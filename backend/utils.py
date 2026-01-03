from PyQt6.QtGui import QIcon, QPixmap, QPainter, QColor, QPen, QBrush
from PyQt6.QtCore import Qt, QPointF


def generate_network_icon():
    size = 256
    pixmap = QPixmap(size, size)
    pixmap.fill(Qt.GlobalColor.transparent)
    painter = QPainter(pixmap)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing)

    # Background: Dark Nord Rounded Rect
    bg_color = QColor("#2e3440")
    painter.setBrush(QBrush(bg_color))
    painter.setPen(Qt.PenStyle.NoPen)
    painter.drawRoundedRect(10, 10, size - 20, size - 20, 60, 60)

    # Network Graph (3 Nodes)
    accent = QColor("#88c0d0")
    painter.setPen(QPen(accent, 12, Qt.PenStyle.SolidLine, Qt.PenCapStyle.RoundCap))
    painter.setBrush(QBrush(accent))

    # Points
    p1 = QPointF(size * 0.5, size * 0.3)  # Top
    p2 = QPointF(size * 0.3, size * 0.7)  # Bottom Left
    p3 = QPointF(size * 0.7, size * 0.7)  # Bottom Right

    # Draw Lines
    painter.drawLine(p1, p2)
    painter.drawLine(p2, p3)
    painter.drawLine(p3, p1)

    # Draw Nodes
    r = 20
    painter.drawEllipse(p1, r, r)
    painter.drawEllipse(p2, r, r)
    painter.drawEllipse(p3, r, r)

    painter.end()
    return QIcon(pixmap)
