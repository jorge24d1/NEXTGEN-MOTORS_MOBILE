import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static final Map<String, Map<String, String>> _localizedValues = {
    'es': {
      'appTitle': 'Concesionario App',
      'hello': 'Hola de nuevo,',
      'nextAppointment': 'PRÓXIMA CITA',
      'yourActivities': 'Tus Actividades',
      'noAppointments': 'No hay citas registradas.',
      'appointmentDetails': 'Detalles de la Cita',
      'requestDate': 'Fecha de Solicitud',
      'assignedDate': 'Fecha Asignada',
      'appointmentInfo': 'Información de la Cita',
      'notesInteraction': 'Notas e Interacción',
      'yourComment': 'Tu Comentario',
      'advisorResponse': 'Respuesta del Asesor',
      'noComments': 'Sin comentarios adicionales.',
      'noResponse': 'Aún no hay respuesta del equipo técnico.',
      'consultDante': 'Consultar con Dante AI',
      'generalMaintenance': 'Mantenimiento General',
      'toConfirm': 'Por confirmar',
      'notAvailable': 'No disponible',
      'approved': 'Aprobada',
      'pending': 'Pendiente',
      'rejected': 'Rechazada',
      'settings': 'Configuración',
      'language': 'Idioma',
      'selectLanguage': 'Selecciona tu idioma',
      'logout': 'Cerrar sesión',
      'vehicle': 'Vehículo',
    },
    'en': {
      'appTitle': 'Dealership App',
      'hello': 'Welcome back,',
      'nextAppointment': 'NEXT APPOINTMENT',
      'yourActivities': 'Your Activities',
      'noAppointments': 'No appointments registered.',
      'appointmentDetails': 'Appointment Details',
      'requestDate': 'Request Date',
      'assignedDate': 'Assigned Date',
      'appointmentInfo': 'Appointment Information',
      'notesInteraction': 'Notes & Interaction',
      'yourComment': 'Your Comment',
      'advisorResponse': 'Advisor Response',
      'noComments': 'No additional comments.',
      'noResponse': 'No response from the technical team yet.',
      'consultDante': 'Consult Dante AI',
      'generalMaintenance': 'General Maintenance',
      'toConfirm': 'To be confirmed',
      'notAvailable': 'Not available',
      'approved': 'Approved',
      'pending': 'Pending',
      'rejected': 'Rejected',
      'settings': 'Settings',
      'language': 'Language',
      'selectLanguage': 'Select your language',
      'logout': 'Log out',
      'vehicle': 'Vehicle',
    },
    'pt': {
      'appTitle': 'App Concessionária',
      'hello': 'Olá novamente,',
      'nextAppointment': 'PRÓXIMO AGENDAMENTO',
      'yourActivities': 'Suas Atividades',
      'noAppointments': 'Nenhum agendamento registrado.',
      'appointmentDetails': 'Detalhes do Agendamento',
      'requestDate': 'Data da Solicitação',
      'assignedDate': 'Data Atribuída',
      'appointmentInfo': 'Informações do Agendamento',
      'notesInteraction': 'Notas e Interação',
      'yourComment': 'Seu Comentário',
      'advisorResponse': 'Resposta do Consultor',
      'noComments': 'Sem comentários adicionais.',
      'noResponse': 'Ainda sem resposta da equipe técnica.',
      'consultDante': 'Consultar Dante AI',
      'generalMaintenance': 'Manutenção Geral',
      'toConfirm': 'A confirmar',
      'notAvailable': 'Não disponível',
      'approved': 'Aprovado',
      'pending': 'Pendente',
      'rejected': 'Rejeitado',
      'settings': 'Configurações',
      'language': 'Idioma',
      'selectLanguage': 'Selecione seu idioma',
      'logout': 'Sair',
      'vehicle': 'Veículo',
    },
    'fr': {
      'appTitle': 'App Concessionnaire',
      'hello': 'Rebonjour,',
      'nextAppointment': 'PROCHAIN RENDEZ-VOUS',
      'yourActivities': 'Vos Activités',
      'noAppointments': 'Aucun rendez-vous enregistré.',
      'appointmentDetails': 'Détails du Rendez-vous',
      'requestDate': 'Date de Demande',
      'assignedDate': 'Date Assignée',
      'appointmentInfo': 'Informations du Rendez-vous',
      'notesInteraction': 'Notes et Interaction',
      'yourComment': 'Votre Commentaire',
      'advisorResponse': 'Réponse du Conseiller',
      'noComments': 'Pas de commentaires supplémentaires.',
      'noResponse': "Pas encore de réponse de l'équipe technique.",
      'consultDante': 'Consulter Dante AI',
      'generalMaintenance': 'Entretien Général',
      'toConfirm': 'À confirmer',
      'notAvailable': 'Non disponible',
      'approved': 'Approuvé',
      'pending': 'En attente',
      'rejected': 'Rejeté',
      'settings': 'Paramètres',
      'language': 'Langue',
      'selectLanguage': 'Choisissez votre langue',
      'logout': 'Déconnexion',
      'vehicle': 'Véhicule',
    },
    'de': {
      'appTitle': 'Autohaus App',
      'hello': 'Willkommen zurück,',
      'nextAppointment': 'NÄCHSTER TERMIN',
      'yourActivities': 'Ihre Aktivitäten',
      'noAppointments': 'Keine Termine registriert.',
      'appointmentDetails': 'Termindetails',
      'requestDate': 'Anfragedatum',
      'assignedDate': 'Zugewiesenes Datum',
      'appointmentInfo': 'Termininformationen',
      'notesInteraction': 'Notizen & Interaktion',
      'yourComment': 'Ihr Kommentar',
      'advisorResponse': 'Beraterantwort',
      'noComments': 'Keine zusätzlichen Kommentare.',
      'noResponse': 'Noch keine Antwort vom technischen Team.',
      'consultDante': 'Dante AI konsultieren',
      'generalMaintenance': 'Allgemeine Wartung',
      'toConfirm': 'Zu bestätigen',
      'notAvailable': 'Nicht verfügbar',
      'approved': 'Genehmigt',
      'pending': 'Ausstehend',
      'rejected': 'Abgelehnt',
      'settings': 'Einstellungen',
      'language': 'Sprache',
      'selectLanguage': 'Wählen Sie Ihre Sprache',
      'logout': 'Abmelden',
      'vehicle': 'Fahrzeug',
    },
    'zh': {
      'appTitle': '汽车经销商',
      'hello': '欢迎回来，',
      'nextAppointment': '下一个预约',
      'yourActivities': '您的活动',
      'noAppointments': '没有注册的预约。',
      'appointmentDetails': '预约详情',
      'requestDate': '申请日期',
      'assignedDate': '分配日期',
      'appointmentInfo': '预约信息',
      'notesInteraction': '备注与互动',
      'yourComment': '您的评论',
      'advisorResponse': '顾问回复',
      'noComments': '没有额外评论。',
      'noResponse': '技术团队尚未回复。',
      'consultDante': '咨询 Dante AI',
      'generalMaintenance': '一般维护',
      'toConfirm': '待确认',
      'notAvailable': '不可用',
      'approved': '已批准',
      'pending': '待处理',
      'rejected': '已拒绝',
      'settings': '设置',
      'language': '语言',
      'selectLanguage': '选择您的语言',
      'logout': '退出登录',
      'vehicle': '车辆',
    },
  };

  String get(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['es']?[key] ??
        key;
  }

  // Convenience getters
  String get appTitle => get('appTitle');
  String get hello => get('hello');
  String get nextAppointment => get('nextAppointment');
  String get yourActivities => get('yourActivities');
  String get noAppointments => get('noAppointments');
  String get appointmentDetails => get('appointmentDetails');
  String get requestDate => get('requestDate');
  String get assignedDate => get('assignedDate');
  String get appointmentInfo => get('appointmentInfo');
  String get notesInteraction => get('notesInteraction');
  String get yourComment => get('yourComment');
  String get advisorResponse => get('advisorResponse');
  String get noComments => get('noComments');
  String get noResponse => get('noResponse');
  String get consultDante => get('consultDante');
  String get generalMaintenance => get('generalMaintenance');
  String get toConfirm => get('toConfirm');
  String get notAvailable => get('notAvailable');
  String get approved => get('approved');
  String get pending => get('pending');
  String get rejected => get('rejected');
  String get settings => get('settings');
  String get language => get('language');
  String get selectLanguage => get('selectLanguage');
  String get logout => get('logout');
  String get vehicle => get('vehicle');

  static const supportedLocales = [
    Locale('es'),
    Locale('en'),
    Locale('pt'),
    Locale('fr'),
    Locale('de'),
    Locale('zh'),
  ];
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['es', 'en', 'pt', 'fr', 'de', 'zh'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
