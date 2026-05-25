import QtQuick 2.15
import QtQuick.Controls 2.15
import QtPositioning 5.15

Item {
    id: ventanaRaiz
    width: 360
    height: 640

    // ========================================================
    // CEREBRO DEL TAXÍMETRO (Versión GPS Real)
    // ========================================================
    QtObject {
        id: taximetroEngine
        property double totalPagar: 0.0
        property double distanciaKm: 0.0
        property bool viajeActivo: false
        
        // Tarifas (ajusta estos valores a tu gusto)
        property double tarifaBase: 1.50   // El "banderazo" inicial
        property double tarifaPorKm: 2.50  // Lo que cobramos por cada KM

        // Guardamos la última coordenada para calcular el delta de movimiento
        property var ultimaCoordenada: null

        function iniciarViaje() {
            viajeActivo = true
            totalPagar = tarifaBase
            distanciaKm = 0.0
            ultimaCoordenada = null // Limpiamos la memoria del último viaje
            gpsSource.start()       // Encendemos el sensor GPS
        }

        function terminarViaje() {
            viajeActivo = false
            gpsSource.stop()        // Apagamos el GPS para ahorrar batería
        }

        // Función matemática para calcular distancia entre dos puntos (X, Y)
        function actualizarDistancia(nuevaCoordenada) {
            if (ultimaCoordenada !== null && ultimaCoordenada.isValid && nuevaCoordenada.isValid) {
                // distanceTo calcula los metros reales entre ambas coordenadas
                var metrosAvanzados = ultimaCoordenada.distanceTo(nuevaCoordenada)
                
                // Si el auto se movió, sumamos la fracción de kilómetros y el dinero
                if (metrosAvanzados > 0) {
                    var kmAvanzados = metrosAvanzados / 1000.0
                    distanciaKm += kmAvanzados
                    totalPagar += (kmAvanzados * tarifaPorKm)
                }
            }
            // Actualizamos la posición para la siguiente lectura
            ultimaCoordenada = nuevaCoordenada
        }
    }

    // ========================================================
    // SENSOR HARDWARE GPS
    // ========================================================
    PositionSource {
        id: gpsSource
        updateInterval: 2000 // Lee el satélite cada 2 segundos (2000 ms)
        active: false

        onPositionChanged: {
            if (position.coordinate.isValid && taximetroEngine.viajeActivo) {
                taximetroEngine.actualizarDistancia(position.coordinate)
            }
        }
    }

    // ========================================================
    // INTERFAZ VISUAL
    // ========================================================
    Column {
        anchors.centerIn: parent
        spacing: 30

        Text {
            text: "TAXIMETRO GPS"
            font.pointSize: 12
            anchors.horizontalCenter: parent.horizontalCenter
        }

        // --- ESTO ES LO QUE CAMBIAMOS PARA EL COLOR VERDE ---
        Text {
            text: "$" + taximetroEngine.totalPagar.toFixed(2)
            color: "green" // <-- ESTA LÍNEA PINTA TODO EL PRECIO EN VERDE
            font.pointSize: 40
            anchors.horizontalCenter: parent.horizontalCenter
        }
        // -----------------------------------------------------

        Text {
            text: "Distancia: " + taximetroEngine.distanciaKm.toFixed(3) + " km"
            font.pointSize: 10
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Item { width: 1; height: 20 }

        Button {
            id: botonIniciar
            width: 260
            height: 55
            text: "INICIAR VIAJE"
            enabled: !taximetroEngine.viajeActivo
            anchors.horizontalCenter: parent.horizontalCenter

            onClicked: {
                taximetroEngine.iniciarViaje();
            }
        }

        Button {
            id: botonTerminar
            width: 260
            height: 55
            text: "TERMINAR VIAJE"
            enabled: taximetroEngine.viajeActivo
            anchors.horizontalCenter: parent.horizontalCenter

            onClicked: {
                taximetroEngine.terminarViaje();
            }
        }
    }
}
