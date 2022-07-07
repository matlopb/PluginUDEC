import QtQuick 2.15
import QtQuick 2.7
import QtQuick.Window 2.15
import QtQuick 2.2
import QtQuick.Controls 1.1
import QtQuick.Controls 2.15 as QQC2
import QtQuick.Controls.Styles 1.1
import QtQml.Models 2.15 as Modelsq
import QtQuick.Layouts 1.1
import QtQuick.Dialogs 1.1
import QtQuick.Window 2.2
import QtQml 2.0

import UM 1.2 as UM
import Cura 1.0 as Cura


UM.Dialog
{
    id: dialog

    title: "Plugin UDEC";
    width: {
        if (Qt.platform.os == "linux"){
            730 * screenScaleFactor
        }
        else if (Qt.platform.os == "windows"){
            900 * screenScaleFactor
        }
        else if (Qt.platform.os == "osx"){
            900 * screenScaleFactor
        }
    }
    height: {
        if (Qt.platform.os == "linux"){
            590 * screenScaleFactor
        }
        else if (Qt.platform.os == "windows"){
            750 * screenScaleFactor
        }
        else if (Qt.platform.os == "osx"){
            750 * screenScaleFactor
        }
    }
    minimumHeight: {
        if (Qt.platform.os == "linux"){
            580 * screenScaleFactor
        }
        else if (Qt.platform.os == "windows"){
            750 * screenScaleFactor
        }
        else if (Qt.platform.os == "osx"){
            750 * screenScaleFactor
        }
    }
    minimumWidth: {
        if (Qt.platform.os == "linux"){
            730 * screenScaleFactor
        }
        else if (Qt.platform.os == "windows"){
            900 * screenScaleFactor
        }
        else if (Qt.platform.os == "osx"){
            900 * screenScaleFactor
        }
    }
    backgroundColor: "#EBEBEB"

    Button
    {
        id: createInstructionsButton;
        width: 200;
        height: 30;
        anchors.right: cancelButton.left;
        anchors.rightMargin: 30;
        anchors.verticalCenter: cancelButton.verticalCenter;
        onClicked:{
            if (gcodeContent.text == "No gcode in system"){
                manager.set_message_params("e", "Operacion invalida", "No existe un codigo G disponible para generar las instrucciones. \n Rebane una figura e intente de nuevo.")
                manager.show_message()
            }
            else if (newFile.checked && newFileName.text == ""){
                manager.set_message_params("e", "Nombre invalido", "Ingrese un nombre para el nuevo archivo")
                manager.show_message()
            }
            else{
                manager.generatePositions(sb.text, sp.text, wb.text, wp.text, ub.text, up.text, armLen.text,
                 printerH.text, radio.text, altura.text, fileTextfield.text, overwrite.checked,
                 newFileDir.text + "/" + newFileName.text + ".L5K", newFileDir.text)
            }
        }

        style: ButtonStyle
        {
            label: Image
            {
                id: writeImage;
                source: "./images/write.png";
                fillMode: Image.PreserveAspectFit;
                horizontalAlignment: Image.AlignLeft;
            }
        }

        Text
        {
            text: qsTr("Generar instrucciones")
            anchors.right: createInstructionsButton.right
            anchors.rightMargin: 10
            anchors.verticalCenter: createInstructionsButton.verticalCenter
        }
    }

    Button
    {
        id: cancelButton;

        width: 100;
        height: 30;
        anchors.right: mainPanel.right;
        anchors.top: mainPanel.bottom;
        anchors.topMargin: 15;
        onClicked: dialog.close();

        style: ButtonStyle
        {
            label: Image
            {
                id: cancelImage;
                source: "./images/cancel.png";
                fillMode: Image.PreserveAspectFit;
                horizontalAlignment: Image.AlignLeft;
            }
        }
        Text
        {
            text: qsTr("Cancelar")
            anchors.right: cancelButton.right
            anchors.rightMargin: 10
            anchors.verticalCenter: cancelButton.verticalCenter
        }
    }

    Rectangle
    {
        id: mainPanel;

        width: 0.95 * parent.width;
        height: 0.95 * parent.height;
        border.width: 1;
        border.color: "#AFAFAF"
        anchors.centerIn: parent;
        anchors.verticalCenterOffset: -20;

        Text
        {
            id: params;

            text: "Parametros de la impresora";
            font.bold: true;
            font.pointSize: 16;
            font.pixelSize: 20;
            anchors.top: parent.top ;
            anchors.topMargin: 20;
            anchors.left: parent.left;
            anchors.leftMargin: 40;
        }

        Text
        {
            id: fileZone;

            text: "Seleccion del archivo de destino";
            font.bold: true;
            font.pointSize: 16;
            font.pixelSize: 20;
            anchors.top: parent.top;
            anchors.topMargin: 20;
            anchors.right: parent.right;
            anchors.rightMargin: 40;
        }

        ColumnLayout
        {
            anchors.horizontalCenter: params.horizontalCenter
            anchors.top: params.bottom;
            anchors.topMargin: 20;
            anchors.left: parent.left;
            anchors.leftMargin: 140;
            spacing: 10;
            z:100
            width: dialog.width*0.2

            TextField
            {
                id: sb;

                width: dialog.width*0.2;
                height: 30;
                placeholderText: qsTr("Dimensión en mm");
                validator: RegExpValidator{ regExp: /\d{1,7}([.]\d{1,3})+$/ }
                text:"538" //(borrar

                Text
                {
                    id: sbTitle;

                    text: qsTr("S_B");
                    anchors.right: parent.left;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.rightMargin: 20;
                }
                Rectangle
                {
                    id: sbHelpZone;

                    width: sbHelpText.contentWidth;
                    height: sbHelpText.contentHeight;
                    border.width: 1;
                    color: "#fffaf0";
                    anchors.left: parent.right;
                    anchors.leftMargin: 20;
                    anchors.verticalCenter: parent.verticalCenter;
                    visible: parent.hovered;
                    z: 100;

                    Text
                    {
                        id: sbHelpText;

                        text: " Es la distancia entre los actuadores del RDL ";
                        anchors.fill: parent;
                    }
                }
            }

            TextField
            {
                id: sp;

                width: dialog.width*0.2;
                height: 30;
                placeholderText: qsTr("Dimensión en mm");
                validator: RegExpValidator{ regExp: /\d{1,7}([.]\d{1,3})+$/ }
                text:"108" //(borrar

                Text
                {
                    id: spTitle;

                    text: qsTr("s_p");
                    anchors.right: parent.left;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.rightMargin: 20;
                }
                Rectangle
                {
                    id: spHelpZone;

                    width: spHelpText.contentWidth;
                    height: spHelpText.contentHeight;
                    border.width: 1;
                    color: "#fffaf0";
                    anchors.left: parent.right;
                    anchors.leftMargin: 20;
                    anchors.verticalCenter: parent.verticalCenter;
                    visible: parent.hovered;
                    z: 100;

                    Text
                    {
                        id: spHelpText;

                        text: " Es la distancia entre los puntos de conexion \n del efector y los brazos del robot ";
                        anchors.fill: parent;
                    }
                }
            }

            TextField
            {
                id: ub;

                width: dialog.width*0.2;
                height: 30;
                placeholderText: qsTr("Dimensión en mm");
                validator: RegExpValidator{ regExp: /\d{1,7}([.]\d{1,3})+$/ }
                text:"411" //(borrar

                Text
                {
                    id: ubTitle;

                    text: qsTr("U_B");
                    anchors.right: parent.left;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.rightMargin: 20;
                }
                Rectangle
                {
                    id: ubHelpZone;

                    width: ubHelpText.contentWidth;
                    height: ubHelpText.contentHeight;
                    border.width: 1;
                    color: "#fffaf0";
                    anchors.left: parent.right;
                    anchors.leftMargin: 20;
                    anchors.verticalCenter: parent.verticalCenter;
                    visible: parent.hovered;
                    z: 100;

                    Text
                    {
                        id: ubHelpText;

                        text: " Es la distancia entre el actuador y el centro \n de la base ";
                        anchors.fill: parent;
                    }
                }
            }

            TextField
            {
                id: up;

                width: dialog.width*0.2;
                height: 30;
                placeholderText: qsTr("Dimensión en mm");
                validator: RegExpValidator{ regExp: /\d{1,7}([.]\d{1,3})+$/ }
                text:"62" //(borrar

                Text
                {
                    id: upTitle;

                    text: qsTr("u_p");
                    anchors.right: parent.left;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.rightMargin: 20;
                }
                Rectangle
                {
                    id: upHelpZone;

                    width: upHelpText.contentWidth;
                    height: upHelpText.contentHeight;
                    border.width: 1;
                    color: "#fffaf0";
                    anchors.left: parent.right;
                    anchors.leftMargin: 20;
                    anchors.verticalCenter: parent.verticalCenter;
                    visible: parent.hovered;
                    z: 100;

                    Text
                    {
                        id: upHelpText;

                        text: " Es la distancia entre el punto de conexion y \n el centro del efector ";
                        anchors.fill: parent;
                    }
                }
            }

            TextField
            {
                id: wb;

                width: dialog.width*0.2;
                height: 30;
                placeholderText: qsTr("Dimensión en mm");
                validator: RegExpValidator{ regExp: /\d{1,7}([.]\d{1,3})+$/ }
                text:"310" //(borrar

                Text
                {
                    id: wbTitle;

                    text: qsTr("W_B");
                    anchors.right: parent.left;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.rightMargin: 20;
                }
                Rectangle
                {
                    id: wbHelpZone;

                    width: wbHelpText.contentWidth;
                    height: wbHelpText.contentHeight;
                    border.width: 1;
                    color: "#fffaf0";
                    anchors.left: parent.right;
                    anchors.leftMargin: 20;
                    anchors.verticalCenter: parent.verticalCenter;
                    visible: parent.hovered;
                    z: 100;

                    Text
                    {
                        id: wbHelpText;

                        text: " Es la distancia entre el centro de la base y \n el punto medio del tramo descrito por S_b ";
                        anchors.fill: parent;
                    }
                }
            }

            TextField
            {
                id: wp;

                width: dialog.width*0.2;
                height: 30;
                placeholderText: qsTr("Dimensión en mm");
                validator: RegExpValidator{ regExp: /\d{1,7}([.]\d{1,3})+$/ }
                text:"31" //(borrar

                Text
                {
                    id: wpTitle;

                    text: qsTr("w_p");
                    anchors.right: parent.left;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.rightMargin: 20;
                }
                Rectangle
                {
                    id: wpHelpZone;

                    width: wpHelpText.contentWidth;
                    height: wpHelpText.contentHeight;
                    border.width: 1;
                    color: "#fffaf0";
                    anchors.left: parent.right;
                    anchors.leftMargin: 20;
                    anchors.verticalCenter: parent.verticalCenter;
                    visible: parent.hovered;
                    z: 100;

                    Text
                    {
                        id: wpHelpText;

                        text: " Es la distancia entre el efector y el punto \n medio del tramo descrito por s_p ";
                        anchors.fill: parent;
                    }
                }
            }

            TextField
            {
                id: armLen;

                width: dialog.width*0.2;
                height: 30;
                placeholderText: qsTr("Dimensión en mm");
                validator: RegExpValidator{ regExp: /\d{1,7}([.]\d{1,3})+$/ }
                text:"983" //(borrar

                Text
                {
                    id: armLenTitle;

                    text: qsTr("Largo de brazo");
                    anchors.right: parent.left;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.rightMargin: 20;
                }
                Rectangle
                {
                    id: armLenHelpZone;

                    width: armLenHelpText.contentWidth;
                    height: armLenHelpText.contentHeight;
                    border.width: 1;
                    color: "#fffaf0";
                    anchors.left: parent.right;
                    anchors.leftMargin: 20;
                    anchors.verticalCenter: parent.verticalCenter;
                    visible: parent.hovered;
                    z: 100;

                    Text
                    {
                        id: armLenHelpText;

                        text: " Es el largo de los brazos de la impresora ";
                        anchors.fill: parent;
                    }
                }
            }

            TextField
            {
                id: printerH;

                width: dialog.width*0.2;
                height: 30;
                placeholderText: qsTr("Dimensión en mm");
                validator: RegExpValidator{ regExp: /\d{1,7}([.]\d{1,3})+$/ }
                text:"1460" //(borrar

                Text
                {
                    id: printerHTitle;

                    text: qsTr("Altura impresora");
                    anchors.right: parent.left;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.rightMargin: 20;
                }
                Rectangle
                {
                    id: printerHHelpZone;

                    width: printerHHelpText.contentWidth;
                    height: printerHHelpText.contentHeight;
                    border.width: 1;
                    color: "#fffaf0";
                    anchors.left: parent.right;
                    anchors.leftMargin: 20;
                    anchors.verticalCenter: parent.verticalCenter;
                    visible: parent.hovered;
                    z: 100;

                    Text
                    {
                        id: printerHHelpText;

                        text: " Es la distancia entre la base del RDL y la \n superficie de impresion ";
                        anchors.fill: parent;
                    }
                }
            }

            TextField
            {
                id: radio;

                width: dialog.width*0.2;
                height: 30;
                placeholderText: qsTr("Dimensión en mm");
                validator: RegExpValidator{ regExp: /\d{1,7}([.]\d{1,3})+$/ }
                text:"225" //(borrar

                Text
                {
                    id: radioTitle;

                    text: qsTr("Radio WS");
                    anchors.right: parent.left;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.rightMargin: 20;
                }
                Rectangle
                {
                    id: radioHelpZone;

                    width: radioHelpText.contentWidth;
                    height: radioHelpText.contentHeight;
                    border.width: 1;
                    color: "#fffaf0";
                    anchors.left: parent.right;
                    anchors.leftMargin: 20;
                    anchors.verticalCenter: parent.verticalCenter;
                    visible: parent.hovered;
                    z: 100;

                    Text
                    {
                        id: radioHelpText;

                        text: " Es el radio de la base del espacio de trabajo ";
                        anchors.fill: parent;
                    }
                }
            }

            TextField
            {
                id: altura;

                width: dialog.width*0.2;
                height: 30;
                placeholderText: qsTr("Dimensión en mm");
                validator: RegExpValidator{ regExp: /\d{1,7}([.]\d{1,3})+$/ }
                text:"500" //(borrar

                Text
                {
                    id: alturaTitle;

                    text: qsTr("Altura WS");
                    anchors.right: parent.left;
                    anchors.verticalCenter: parent.verticalCenter;
                    anchors.rightMargin: 20;
                }
                Rectangle
                {
                    id: alturaHelpZone;

                    width: alturaHelpText.contentWidth;
                    height: alturaHelpText.contentHeight;
                    border.width: 1;
                    color: "#fffaf0";
                    anchors.left: parent.right;
                    anchors.leftMargin: 20;
                    anchors.verticalCenter: parent.verticalCenter;
                    visible: parent.hovered;
                    z: 100;

                    Text
                    {
                        id: alturaHelpText;

                        text: " Es la altura del espacio de trabajo ";
                        anchors.fill: parent;
                    }
                }
            }
        }

        TextField
        {
            id: fileTextfield;

            width: 150;
            height: fileButton.height;
            anchors.right: fileButton.left;
            anchors.verticalCenter: fileButton.verticalCenter;
            placeholderText: "Seleccione un archivo";
            text: fileDialog.fileUrl;

            Text
            {
                id: fileTextTitle;

                text: qsTr("Archivo de destino");
                anchors.right: parent.left;
                anchors.verticalCenter: parent.verticalCenter;
                anchors.rightMargin: 20;
            }
        }

        Button
        {
            id: fileButton;

            width: 50;
            height: 30;
            anchors.right: mainPanel.right;
            anchors.rightMargin: 20;
            anchors.top: fileZone.bottom;
            anchors.topMargin: 20;
            onClicked: fileDialog.open();

            style: ButtonStyle
            {
                label: Image
                {
                    id: fileImage;
                    source: "./images/browse.png";
                    fillMode: Image.PreserveAspectFit;
                }
            }
        }

        FileDialog
        {
            id: fileDialog;
            title: "seleccione un archivo compatible";
            nameFilters: ["Archivos RSLogix (*.L5K)","Todos los archivos(*)"];
            folder: shortcuts.documents;
            onAccepted:
            {
                console.log("Se ha seleccionado " + fileDialog.fileUrl);
                fileContent.text = manager.showFileContent(fileDialog.fileUrl);
                fileDialog.close()
            }
            onRejected:
            {
                console.log("Canceled")
                fileDialog.quit()
            }
        }

        ColumnLayout
        {
            id: selector;

            anchors.top: fileTextfield.bottom;
            anchors.topMargin: 20;
            anchors.horizontalCenter: fileTextfield.horizontalCenter;
            ExclusiveGroup{ id: writeMethod}

            RadioButton
            {
                id: overwrite;

                checked: true;
                text: qsTr("Sobrescribir");
                exclusiveGroup: writeMethod;
            }

            RadioButton
            {
                id: newFile;

                text: qsTr("Crear copia");
                exclusiveGroup: writeMethod;
            }
        }

        TextField
        {
            id: newFileName;

            width: 200;
            height: fileButton.height;
            anchors.right: mainPanel.right;
            anchors.rightMargin: 20;
            anchors.top: selector.bottom ;
            anchors.topMargin: 20;
            placeholderText: "Indique un nombre";
            enabled: newFile.checked;
            validator: RegularExpressionValidator { regularExpression: /^[a-zA-Z0-9-_]+$/ }

            Text
            {
                id: newFileText;

                text: qsTr("Nombre del archivo");
                anchors.right: parent.left;
                anchors.verticalCenter: parent.verticalCenter;
                anchors.rightMargin: 20;
            }
        }

        TextField
        {
            id: newFileDir;

            width: 150;
            height: dirButton.height;
            anchors.right: dirButton.left;
            anchors.verticalCenter: dirButton.verticalCenter;
            placeholderText: "Seleccione una carpeta";
            text: dirDialog.folder;
            enabled: newFile.checked;

            Text
            {
                id: dirText;

                text: qsTr("Carpeta de destino");
                anchors.right: parent.left;
                anchors.verticalCenter: parent.verticalCenter;
                anchors.rightMargin: 20;
            }
        }

        Button
        {
            id: dirButton;

            width: 50;
            height: 30;
            anchors.right: mainPanel.right;
            anchors.rightMargin: 20;
            anchors.top: newFileName.bottom ;
            anchors.topMargin: 20;
            onClicked: dirDialog.open();
            enabled: newFile.checked;

            style: ButtonStyle
            {
                label: Image
                {
                    id: dirImage;
                    source: "./images/browse.png";
                    fillMode: Image.PreserveAspectFit;
                }
            }
        }

        FileDialog
        {
            id: dirDialog;
            title: "Seleccione una carpeta";
            selectFolder: true;
            folder: shortcuts.documents;
            onAccepted:
            {
                console.log("Se ha seleccionado el directorio " + dirDialog.folder);
                dirDialog.close()
            }
        }

        Rectangle
        {
            id: gcodeZone;

            width: mainPanel.width * 0.46;
            height: mainPanel.height * 0.35;
            anchors.top: altura.bottom;
            anchors.topMargin: 20;
            anchors.bottom: mainPanel.bottom;
            anchors.bottomMargin: 30;
            anchors.left: mainPanel.left;
            anchors.leftMargin: 20;
            anchors.right: mainPanel.horizontalCenter;
            anchors.rightMargin: 5;
            border.width: 1;
            Flickable
            {
                id: gcodeflickable;

                width: parent.width;
                height: parent.height;

                TextArea
                {
                    id: gcodeContent;

                    readOnly: true;
                    text: qsTr(manager.showGcode());
                    width: parent.width;
                    height: parent.height;
                    wrapMode: TextArea.WorldWrap;
                }

                QQC2.ScrollBar.vertical: QQC2.ScrollBar
                {
                    parent: gcodeflickable.parent
                    anchors.top: gcodeflickable.top
                    anchors.left: gcodeflickable.right
                    anchors.bottom: gcodeflickable.bottom
                }
                QQC2.ScrollBar.horizontal: QQC2.ScrollBar
                {
                    parent: fileContentZone
                    anchors.right: gcodeflickable.right
                    anchors.left: gcodeflickable.left
                    anchors.bottom: gcodeflickable.bottom
                }

            }
        }

        Text {
            id: gcodeTitle

            text: qsTr("G-code Seleccionado");
            font.bold: true;
            font.pointSize: 16;
            font.pixelSize: 20;
            anchors.horizontalCenter: gcodeZone.horizontalCenter;
            anchors.top: gcodeZone.bottom;
        }

        Rectangle
        {
            id: fileContentZone;

            width: mainPanel.width * 0.46;
            height: mainPanel.height * 0.35;
            anchors.verticalCenter: gcodeZone.verticalCenter;
            anchors.bottom: mainPanel.bottom;
            anchors.bottomMargin: 30;
            anchors.right: mainPanel.right;
            anchors.rightMargin: 20;
            anchors.left: mainPanel.horizontalCenter;
            anchors.leftMargin: 5;
            border.width: 1;

            Flickable
            {
                id: flickable;

                width: parent.width;
                height: parent.height;

                TextArea
                {
                    id: fileContent;

                    readOnly: true;
                    width: parent.width;
                    height: parent.height;
                    wrapMode: TextArea.WorldWrap;
                }

                QQC2.ScrollBar.vertical: QQC2.ScrollBar
                {
                    parent: flickable.parent
                    anchors.top: flickable.top
                    anchors.left: flickable.right
                    anchors.bottom: flickable.bottom
                }
                QQC2.ScrollBar.horizontal: QQC2.ScrollBar
                {
                    parent: fileContentZone
                    anchors.right: flickable.right
                    anchors.left: flickable.left
                    anchors.bottom: flickable.bottom
                }

            }
        }

        Text {
            id: fileContentTitle

            text: qsTr("Archivo de destino seleccionado");
            font.bold: true;
            font.pointSize: 16;
            font.pixelSize: 20;
            anchors.horizontalCenter: fileContentZone.horizontalCenter;
            anchors.top: fileContentZone.bottom;
        }
    }
}
