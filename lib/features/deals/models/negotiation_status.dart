enum NegotiationStatus {
  propuesta,
  contraofertada,
  acordada,
  completada,
  rechazada,
  cancelada;

  static NegotiationStatus fromString(String status) {
    switch (status.toLowerCase()) {
      case 'contraofertada':
        return NegotiationStatus.contraofertada;
      case 'acordada':
        return NegotiationStatus.acordada;
      case 'completada':
        return NegotiationStatus.completada;
      case 'rechazada':
        return NegotiationStatus.rechazada;
      case 'cancelada':
        return NegotiationStatus.cancelada;
      case 'propuesta':
      default:
        return NegotiationStatus.propuesta;
    }
  }

  String toShortString() {
    return name;
  }

  String toDisplayName() {
    switch (this) {
      case NegotiationStatus.propuesta:
        return 'Pendiente';
      case NegotiationStatus.contraofertada:
        return 'Contraoferta';
      case NegotiationStatus.acordada:
        return 'Acordado';
      case NegotiationStatus.completada:
        return 'Completado';
      case NegotiationStatus.rechazada:
        return 'Rechazado';
      case NegotiationStatus.cancelada:
        return 'Cancelado';
    }
  }
}
