import math
import multiprocessing
import os.path
import platform
import time
from multiprocessing import Lock
from multiprocessing.sharedctypes import Array
from threading import Thread
from typing import List, cast

from PyQt5.QtCore import QObject, pyqtSlot
from UM.Application import Application
from UM.Extension import Extension
from UM.Logger import Logger
from UM.PluginRegistry import PluginRegistry
from UM.i18n import i18nCatalog
from cura.CuraApplication import CuraApplication

i18n_catalog = i18nCatalog("PluginUDEC")  # Translates to a language Cura can read


def threaded(fn):
    def wrapper(*args, **kwargs):
        Thread(target=fn, args=args, kwargs=kwargs).start()
        # multiprocessing.Process(target=fn, args=args, kwargs=kwargs).start()
    return wrapper


class PluginUDEC(QObject, Extension):
    def __init__(self) -> None:
        super().__init__()
        QObject.__init__(self)
        Extension.__init__(self)

        self.setMenuName(i18n_catalog.i18nc("@item:inmenu", "Plugin UDEC"))
        self.addMenuItem(i18n_catalog.i18nc("@item:inmenu", "Generar archivo RSLogix"), self.show_popup)
        self._view = None
        self.message_view = None
        self.progress_bar_view = None
        self.progress_value = 0
        self.positions_list = []

    lock = Lock()
    end_flag = multiprocessing.Value('b', True)
    message_flag = multiprocessing.Value('b', False)
    message_title = Array('c', 40, lock=lock)
    message_content = Array('c', 140, lock=lock)
    message_style = Array('c', 10, lock=lock)

    @pyqtSlot(result=str)
    def showGcode(self) -> str:
        """Shows the available gcode (if any) on the corresponding zone."""

        gcode = self.get_gcode()
        if len(gcode) < 20:
            return ''.join(gcode)
        gcode = self.split_lines(gcode)
        gcode_string = self.match_text(gcode, 'LAYER:')
        gcode_string = ' '.join(gcode_string)
        return gcode_string

    @threaded
    def generatePositionsAsync(self, sb, sp, wb, wp, ub, up, arm_length, height, ws_radio, ws_height, file_path,
                               overwrite, destination_path=None, dir_path=None) -> None:
        """Called when the user presses the 'generate instructions' button. Responsible for using the given parameters
         to call the functions which calculate the instructions and then write them in a L5K file."""

        print("SE INICIO EL PROCESO GENERATEPOSITIONS ASYNC")
        params = [sb, sp, wb, wp, ub, up, arm_length, height, ws_radio, ws_height]
        file_params = [file_path, overwrite, destination_path, dir_path]
        if self.are_valid(params, file_params) is False:
            print("ERROR DE VALIDACION")
            self.end_flag.value = False
            return
        coordinates = self.get_coordinates(self.split_lines(self.get_gcode()))
        if self.check_ws(ws_radio, ws_height, coordinates):
            ws_coordinates = self.z_bias(coordinates, float(height))
            parameters = [sb, sp, wb, wp, ub, up, arm_length, ws_radio]
            try:
                self.inv_kin_problem(ws_coordinates, parameters)
                print("SE CALCULO EL PROBLEMA INVERSO")
            except ValueError:
                self.set_message_params('e', 'Se produjo un error', 'Se ha producido un error de calculo. Por favor '
                                                                    'revise que los datos de impresora esten '
                                                                    'correctos')
                self.end_flag.value = False
                return
            self.generateInstructions(file_path, overwrite, self.positions_list, destination_path)
            self.end_flag.value = False
            print(
                "#################################################################################################################################"
                "###################################################################################################################################")
            self.set_message_params('i', 'Operacion finalizada', 'Se termino la generacion de instrucciones. Las '
                                                                 'instrucciones fueron guardadas en el archivo '
                                                                 'indicado')
            print("SE MPIEZA EL PROCESO DE ABRIR LA VENTANA DE FIN DE PROCESO")

    @pyqtSlot(float, float, float, float, float, float, float, float, float, float, str, bool, str, str)
    def generatePositions(self, sb, sp, wb, wp, ub, up, arm_length, height, ws_radio, ws_height, file_path, overwrite,
                          destination_path=None, dir_path=None) -> None:
        """Called when the user presses the 'generate instructions' button. Responsible for using the given parameters
         to call the functions which calculate the instructions and then write them in a L5K file."""

        self.set_message_params('i', 'Proceso en curso', 'Calculando las posiciones')
        self.show_message()

        self.generatePositionsAsync(sb, sp, wb, wp, ub, up, arm_length, height, ws_radio, ws_height, file_path,
                                    overwrite, destination_path, dir_path)
        while self.end_flag.value:
            print("Endflag is: ", self.end_flag.value)
            time.sleep(1)
        self.show_message()
        self.end_flag.value = True

    def are_valid(self, params, file_params) -> bool:
        print("EN PROCESO DE VALIDACION")
        if 0 in params:
            self.set_message_params('e', 'Faltan datos', 'Ingrese todos los datos solicitados e intente otra vez')
            return False
        if file_params[1]:
            if not os.path.isfile(self.get_url(file_params[0])):
                print("no existe archivo")
                self.set_message_params('e', 'Archivo inexistente',
                                        'El archivo indicado no es compatible o no existe.\nPor favor seleccione un '
                                        'archivo valido.')
                return False
        if not file_params[1]:
            if not os.path.isfile(self.get_url(file_params[0])):
                self.set_message_params('e', 'Archivo inexistente',
                                        'El archivo indicado no es compatible o no existe.\nPor favor seleccione un '
                                        'archivo valido.')
                return False
            elif os.path.isfile(self.get_url(file_params[2])):
                self.set_message_params('e', 'Archivo ya existe',
                                        'El archivo ya existe.\nPor favor escoja otro nombre.')
                return False
            elif not os.path.exists(self.get_url(file_params[3])):
                self.set_message_params('e', 'Carpeta inexistente',
                                        'La carpeta indicada no existe.\nPor favor seleccione un directorio valido.')
                return False
        return True

    def check_ws(self, radio, height, coordinates) -> bool:
        """Checks if the given coordinates fit in the working space"""

        for i in range(len(coordinates)):
            if abs(coordinates[i][0]) > radio or abs(coordinates[i][1]) > radio or abs(coordinates[i][2]) > height:
                self.set_message_params('Coordenadas incompatibles', 'La figura revanada es mas grande que el espacio'
                                                               ' de trabajo disponible')
                return False
        return True

    def z_bias(self, coordinates, height) -> List[List[float]]:
        """Returns the given coordinates with an added bias on the Z axis. This bias depends on the specified RDL
        height """

        for i in range(len(coordinates)):
            coordinates[i][2] -= height
        return coordinates

    def inv_kin_problem(self, coordinates, parameters) -> None:  # List[List[float]]:
        """Returns the positions of the motors for each given coordinate"""

        a = (parameters[0] - parameters[1]) / 2
        b = parameters[2] - parameters[3]
        c = parameters[5] - parameters[4]
        l = parameters[6]
        x = self.get_column(coordinates, 0)
        y = self.get_column(coordinates, 1)
        z = self.get_column(coordinates, 2)
        # L = []
        for i in range(len(coordinates)):
            C1 = x[i] ** 2 + y[i] ** 2 + z[i] ** 2 + a ** 2 + b ** 2 + 2 * a * x[i] + 2 * b * y[i] - l ** 2
            C2 = x[i] ** 2 + y[i] ** 2 + z[i] ** 2 + a ** 2 + b ** 2 - 2 * a * x[i] + 2 * b * y[i] - l ** 2
            C3 = x[i] ** 2 + y[i] ** 2 + z[i] ** 2 + c ** 2 + 2 * c * y[i] - l ** 2
            L1 = -z[i] - math.sqrt(z[i] ** 2 - C1)
            L2 = -z[i] - math.sqrt(z[i] ** 2 - C2)
            L3 = -z[i] - math.sqrt(z[i] ** 2 - C3)
            # L.append([round(L1, 3), round(L2, 3), round(L3, 3)])
            self.positions_list.append([round(L1, 3), round(L2, 3), round(L3, 3)])

            # self.progress_value = len(coordinates) / (i + 1)
            # self.progress_changed.emit(self.progress_value)
        # return L

    def get_column(self, coordinates, column) -> List[float]:
        """Returns the specified column from the given List"""

        axis = []
        for i in range(len(coordinates)):
            axis.append(coordinates[i][column])
        return axis  # numpy.array(axis)

    def split_lines(self, base_text) -> List[str]:
        """Splits the given text into lines and saves them onto a list. Returns the list."""

        lines = [""]
        line_list = [""]
        for line in base_text:
            lines += line
            if self.match_inline(['\n'])(line):
                line_list.append(''.join(lines))
                lines = [""]
        return line_list

    def match_text(self, base_text, find) -> List[str]:
        """Reads a given text and stores its content up until a match is found. Returns stored content."""

        content = [""]
        for line in base_text:
            content[0] += line
            if self.match_inline([find])(line):
                break
        return content

    def get_gcode(self) -> List[str]:
        """Gets the available gcode (if any) from the Cura build plate."""

        scene = Application.getInstance().getController().getScene()
        if not hasattr(scene, "gcode_dict"):
            Logger.log("e", "no gcode in system")
            return ["No gcode in system"]
        gcode_dict = getattr(scene, "gcode_dict")
        if not gcode_dict:
            Logger.log("e", "no gcode in system")
            return ["No gcode in system"]
        active_build_plate_id = CuraApplication.getInstance().getMultiBuildPlateModel().activeBuildPlate
        gcode_list = gcode_dict[active_build_plate_id]
        gcodeList = [""]
        for i in range(len(gcode_list)):
            gcodeList += str(gcode_list[i])
        return gcodeList

    def get_coordinates(self, gcode) -> List[List[float]]:
        """Gets the XYZ coordinates from the G code and stores them in a list."""

        filtered_lines = list(filter(self.match_inline([' X', ' Y', ' Z']), gcode))
        coordinates = []
        x_axis = 1
        y_axis = 1
        z_axis = 1
        for line in filtered_lines:
            words = line.split()
            if self.match_inline(['X'])(line):
                x_axis = self.get_values('X', words)
            if self.match_inline(['Y'])(line):
                y_axis = self.get_values('Y', words)
            if self.match_inline(['Z'])(line):
                z_axis = self.get_values('Z', words)
            coordinates.append([x_axis, y_axis, z_axis])
        Logger.log('i', "The number of coordinates is " + str(len(coordinates)))
        return coordinates

    def get_values(self, axis, line) -> float:
        """Returns the values of the coordinates from the G code"""

        axis_values = list(filter(self.match_inline([axis]), line))
        axis_values = self.to_int(axis_values)
        return axis_values

    def to_int(self, word) -> float:
        """Returns the value in the given word as a float"""

        value = list(filter(self.is_int, list(word[0])))
        value = ''.join(value)
        value = float(value)
        return value

    def is_int(self, element) -> bool:
        """Returns true if the element holds a number representing a component of a coordinate"""

        if 'X' in element or 'Y' in element or 'Z' in element:
            return False
        else:
            return True

    def get_url(self, url) -> str:
        """get the real URL for the selected file"""

        if platform.system() == 'Windows':
            fileUrl = self.get_os_path(url, '')
            return fileUrl
        fileUrl = self.get_os_path(url, '/')
        return fileUrl

    def get_os_path(self, url, separator) -> str:
        tmp = [separator]
        for i in range(len(url)):
            if i > 7:
                tmp[0] += str(url[i])
        file_path = ''.join(tmp)
        return file_path

    @pyqtSlot(str, result=str)
    def showFileContent(self, url) -> str:
        """Show the content of the selected file in the bottom right text box."""

        file = open(self.get_url(url), mode='r', encoding='utf-8')
        content = file.read()
        file.close()
        return content

    def write_file(self, file_path, destination_path, positions, action) -> None:
        """Copies the content of file_path in destination_path while adding extra content"""

        file = open(self.get_url(file_path), mode='r', encoding='utf-8')
        file_read = file.readlines()
        text = self.get_matrix(positions)
        with open(self.get_url(destination_path), action, encoding='utf-8') as file_write:
            for line in file_read:
                file_write.write(line)
                if self.match_inline(['\t\t\tTAG'])(line):
                    file_write.write(str(text) + '\n')
        file.close()

    def get_matrix(self, positions) -> str:
        """Returns the given positions formatted as a RSLogix 5000 matrix TAG"""

        L: str = '\t\t\t\tMatriz_L : REAL[' + str(
            len(positions)) + ',3](Description := "matriz de posiciones",' + '\n'
        L += '\t\t\t\t            RADIX := Float) := ['
        for i in range(0, len(positions), 2):
            try:
                if i is not 0:
                    L += '						,'
                L += ''.join(str(positions[i][0])) + ',' + ''.join(str(positions[i][1])) + ',' + ''.join(
                    str(positions[i][2])) + ',' + ''.join(str(positions[i + 1][0])) + ',' + ''.join(
                    str(positions[i + 1][1])) + ',' + ''.join(str(positions[i + 1][2])) + '\n'
            except IndexError:
                L += ''.join(str(positions[i][0])) + ',' + ''.join(str(positions[i][1])) + ',' + ''.join(
                    str(positions[i][2])) + '\n'
        L += '						]' + ';'
        return L

    def generateInstructions(self, file_path, overwrite, positions, destination_path=None) -> None:
        """Generates the instructions by either overwriting the base file or creating a new one."""

        if overwrite:
            self.write_file(file_path, file_path, positions, 'w')
        if not overwrite:
            self.write_file(file_path, destination_path, positions, 'x')

    def match_inline(self, find):
        """Looks for a match between 2 strings"""

        def find_word(line) -> bool:

            for i in range(len(find)):
                if find[i] in line:
                    return True
            return False

        return find_word

    def create_view(self, view) -> None:
        """Creates the view to be used."""

        Logger.log("d", "Creating requested view.")
        path = os.path.join(cast(str, PluginRegistry.getInstance().getPluginPath("PluginUDEC")), view)
        if view == "main.qml":
            self._view = CuraApplication.getInstance().createQmlComponent(path, {"manager": self})
            print("-----------------------", self._view.contentItem)
            if self._view is None:
                Logger.log("e",
                           "Not creating Plugin UDEC window since the view variable is empty.")
                return
            Logger.log("d", "Plugin UDEC view created.")
        if view == "MessageDialog.qml":
            print("SE ESTA CREANDO LA VENTANA DE MENSAJES")
            self.message_view = CuraApplication.getInstance().createQmlComponent(path, {"manager": self})
            print("SE ASIGNO LA VENTANA A LA VARIABLE")
            if self.message_view is None:
                Logger.log("e",
                           "Not creating message window since the message view variable is empty.")
                return
            Logger.log("d", "Message view created.")
        if view == "progressbar.qml":
            self.progress_bar_view = CuraApplication.getInstance().createQmlComponent(path, {"manager": self})
            if self.progress_bar_view is None:
                Logger.log("e",
                           "Not creating progress bar window since the message view variable is empty.")
                return
            Logger.log("d", "progress bar created.")

    def show_popup(self) -> None:
        """Show the GUI of the UDEC Plugin."""

        self.create_view("main.qml")
        if self._view is None:
            Logger.log("e", "Not creating Plugin UDEC window since the QML component failed to be created.")
            return
        self._view.show()

    @pyqtSlot(result=str)
    def get_message_title(self) -> str:
        title = str(self.message_title.value)
        title = title[2:-1]
        return title

    @pyqtSlot(result=str)
    def get_message_content(self) -> str:
        content = str(self.message_content.value)
        content = content[2:-1]
        return content

    @pyqtSlot(result=str)
    def get_message_style(self) -> str:
        style = str(self.message_style.value)
        style = style[2:-1]
        return style

    @pyqtSlot(str, str, str)
    def set_message_params(self, style, title, content) -> None:
        self.message_style.value = bytes(style, 'utf-8')
        self.message_title.value = bytes(title, 'utf-8')
        self.message_content.value = bytes(content, 'utf-8')

    @pyqtSlot()
    def show_message(self) -> None:
        """Displays an error message with the given title and message"""

        self.create_view("MessageDialog.qml")
        if self.message_view is None:
            Logger.log("e", "Not creating message window since the QML component failed to be created.")
            return
        self.message_view.show()
