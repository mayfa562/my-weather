import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import '../providers/weather_provider.dart';

class AppStrings {
  final String languageCode;
  const AppStrings(this.languageCode);

  static AppStrings of(BuildContext context) {
    try {
      return AppStrings(context.watch<WeatherProvider>().languageCode);
    } on ProviderNotFoundException {
      return const AppStrings('en');
    }
  }

  String _text(String en, String es, String fr) => switch (languageCode) {
        'es' => es,
        'fr' => fr,
        _ => en,
      };

  String get appName => 'My weather';
  String get weather => _text('Weather', 'Clima', 'Météo');
  String get menu => _text('Menu', 'Menú', 'Menu');
  String get home => _text('Home', 'Inicio', 'Accueil');
  String get searchCity =>
      _text('Search city', 'Buscar ciudad', 'Rechercher une ville');
  String get settings => _text('Settings', 'Configuración', 'Réglages');
  String get radar => _text('Radar', 'Radar', 'Radar');
  String get weatherTools =>
      _text('Weather tools', 'Herramientas del tiempo', 'Outils météo');
  String get weatherToolsSubtitle => _text(
      'Explore weather features and saved places',
      'Explora funciones meteorológicas y lugares guardados',
      'Explorez les fonctions météo et vos lieux enregistrés');
  String get starredCities =>
      _text('Starred Cities', 'Ciudades favoritas', 'Villes favorites');
  String get weatherAlerts =>
      _text('Weather Alerts', 'Alertas meteorológicas', 'Alertes météo');
  String get liveRadar =>
      _text('Live Radar', 'Radar en vivo', 'Radar en direct');
  String get liveRadarSubtitle => _text('See rain around you',
      'Mira la lluvia a tu alrededor', 'Voir la pluie autour de vous');
  String get savedCities =>
      _text('Saved Cities', 'Ciudades guardadas', 'Villes enregistrées');
  String get savedLocationsAtGlance => _text(
      'Your favorite locations at a glance',
      'Tus ubicaciones favoritas de un vistazo',
      'Vos lieux favoris en un coup d’œil');
  String get starCityHint => _text(
      'Star a city from the weather screen to see it here.',
      'Marca una ciudad desde la pantalla del tiempo para verla aquí.',
      'Ajoutez une ville depuis l’écran météo pour la voir ici.');
  String get alerts => _text('Alerts', 'Alertas', 'Alertes');
  String get profile => _text('Profile', 'Perfil', 'Profil');
  String get appPreferences => _text(
      'App Preferences', 'Preferencias de la app', 'Préférences de l’app');
  String get language => _text('Language', 'Idioma', 'Langue');
  String get yourName => _text('Your name', 'Tu nombre', 'Votre nom');
  String get greetingHint => _text(
      'Used to greet you on the home screen',
      'Se usa para saludarte en la pantalla principal',
      'Utilisé pour vous saluer sur l’écran d’accueil');
  String get about => _text('About', 'Acerca de', 'À propos');
  String get createdBy =>
      _text('Created by Mayfa', 'Creado por Mayfa', 'Créé par Mayfa');
  String get noWeatherYet => _text('No weather yet',
      'Aún no hay datos del tiempo', 'Aucune météo pour le moment');
  String get noStarredCities => _text(
      'No starred cities yet. Tap the star next to a city’s name on the home screen to keep track of it here.',
      'Aún no hay ciudades favoritas. Toca la estrella junto al nombre de una ciudad para verla aquí.',
      'Aucune ville favorite. Touchez l’étoile à côté du nom d’une ville pour la retrouver ici.');
  String get locationPrompt => _text(
      'Grant location access, or tap + to search a city.',
      'Permite el acceso a la ubicación o toca + para buscar una ciudad.',
      'Autorisez la position ou touchez + pour rechercher une ville.');
  String get fetchingWeather => _text('Fetching weather...',
      'Obteniendo el tiempo...', 'Récupération de la météo...');
  String get somethingWentWrong => _text(
      'Something went wrong.', 'Algo salió mal.', 'Une erreur est survenue.');
  String get pleaseTryAgain =>
      _text('Please try again.', 'Inténtalo de nuevo.', 'Veuillez réessayer.');
  String get tryAgain => _text('Try again', 'Reintentar', 'Réessayer');
  String get hourlyForecast =>
      _text('Hourly Forecast', 'Pronóstico por horas', 'Prévisions horaires');
  String get next24Hours =>
      _text('Next 24 hours', 'Próximas 24 horas', 'Prochaines 24 heures');
  String get fiveDayForecast =>
      _text('5-Day Forecast', 'Pronóstico de 5 días', 'Prévisions à 5 jours');
  String get viewAll => _text('View all', 'Ver todo', 'Tout voir');
  String get useCurrentLocation => _text('Use current location',
      'Usar ubicación actual', 'Utiliser la position actuelle');
  String get useMyLocation =>
      _text('Use my location', 'Usar mi ubicación', 'Utiliser ma position');
  String get saveCity =>
      _text('Save city', 'Guardar ciudad', 'Enregistrer la ville');
  String get searchCityHint =>
      _text('Search city...', 'Buscar ciudad...', 'Rechercher une ville...');
  String get noMatchingCities => _text(
      'No matching cities found — check the spelling, or try a broader search.',
      'No se encontraron ciudades — revisa la ortografía o prueba una búsqueda más amplia.',
      'Aucune ville trouvée. Vérifiez l’orthographe ou essayez une recherche plus générale.');
  String get couldntLoad =>
      _text('Couldn’t load', 'No se pudo cargar', 'Impossible de charger');
  String get updatingWeather => _text('Updating weather…',
      'Actualizando el tiempo…', 'Mise à jour de la météo…');
  String get remove => _text('Remove', 'Eliminar', 'Supprimer');
  String get backToToday =>
      _text('Back to Today', 'Volver a hoy', 'Retour à aujourd’hui');
  String get today => _text('TODAY', 'HOY', 'AUJOURD’HUI');
  String get now => _text('NOW', 'AHORA', 'MAINTENANT');
  String get precipitation =>
      _text('Precipitation', 'Precipitación', 'Précipitations');
  String get humidity => _text('Humidity', 'Humedad', 'Humidité');
  String get windSpeed =>
      _text('Wind speed', 'Velocidad del viento', 'Vitesse du vent');
  String get temperatureRange => _text(
      'Temperature range', 'Rango de temperatura', 'Plage de température');
  String get feelsLike => _text('Feels like', 'Sensación térmica', 'Ressenti');
  String get chooseLanguage => _text(
      'Choose your language', 'Elige tu idioma', 'Choisissez votre langue');
  String get getStarted => _text('Get started', 'Comenzar', 'Commencer');
  String get welcomeToMyWeather => _text('Welcome to My weather',
      'Bienvenido a My weather', 'Bienvenue sur My weather');
  String get weatherMadeSimple => _text('Weather, made simple.',
      'El tiempo, de forma sencilla.', 'La météo, en toute simplicité.');
  String get personalizedForecast => _text(
      'Get a personalized forecast for your day.',
      'Obtén un pronóstico personalizado para tu día.',
      'Obtenez une météo personnalisée pour votre journée.');
  String get continueButton => _text('Continue', 'Continuar', 'Continuer');
  String get skipForNow =>
      _text('Skip for now', 'Omitir por ahora', 'Passer pour le moment');
  String get tellUsYourName => _text('What should we call you?',
      '¿Cómo te llamamos?', 'Comment devons-nous vous appeler ?');
  String get namePersonalizationHint => _text(
      'We’ll use your name to personalize your weather experience.',
      'Usaremos tu nombre para personalizar tu experiencia del tiempo.',
      'Nous utiliserons votre nom pour personnaliser votre expérience météo.');
  String get enterName =>
      _text('Enter your name', 'Escribe tu nombre', 'Entrez votre nom');
  String get saveAndContinue => _text(
      'Save & continue', 'Guardar y continuar', 'Enregistrer et continuer');
  String get cancel => _text('Cancel', 'Cancelar', 'Annuler');
  String get proceed => _text('Proceed', 'Continuar', 'Continuer');
  String get whatShouldWeCallYou => _text('What should we call you?',
      '¿Cómo te llamamos?', 'Comment devons-nous vous appeler ?');
  String get skip => _text('Skip', 'Omitir', 'Passer');
  String get save => _text('Save', 'Guardar', 'Enregistrer');
  String get nameHint => _text('Your name', 'Tu nombre', 'Votre nom');
  String get personalizeWeather => _text('Personalize your weather',
      'Personaliza tu tiempo', 'Personnalisez votre météo');
  String get makeAppYours => _text('Make the app feel like yours.',
      'Haz que la app sea tuya.', 'Faites de l’app la vôtre.');
  String get significantChanges => _text(
      'Significant changes can trigger local notifications.',
      'Los cambios importantes pueden activar notificaciones locales.',
      'Les changements importants peuvent déclencher des notifications locales.');
  String get builtWith => _text(
      'Built with Flutter · OpenWeatherMap · OpenStreetMap',
      'Creada con Flutter · OpenWeatherMap · OpenStreetMap',
      'Créée avec Flutter · OpenWeatherMap · OpenStreetMap');
  String get dailyForecast => _text(
      'Your daily forecast', 'Tu pronóstico diario', 'Votre météo quotidienne');
  String get stayPrepared => _text(
      'Stay prepared wherever you go.',
      'Mantente preparado dondequiera que vayas.',
      'Restez prêt où que vous soyez.');
  String get stayPreparedShort =>
      _text('Stay prepared', 'Mantente preparado', 'Restez prêt');
  String get importantChanges => _text(
      'We’ll notify you about important weather changes.',
      'Te avisaremos de los cambios meteorológicos importantes.',
      'Nous vous avertirons des changements météo importants.');
  String get weatherAlertMessage => _text(
      'You will receive a notification when the app detects a significant weather change during a refresh.',
      'Recibirás una notificación cuando la app detecte un cambio meteorológico importante durante una actualización.',
      'Vous recevrez une notification lorsque l’app détectera un changement météo important lors d’une actualisation.');
  String get gotIt => _text('Got it', 'Entendido', 'Compris');
  String get dailyOutlook =>
      _text('Daily outlook', 'Pronóstico diario', 'Prévisions quotidiennes');
  String highLow(int high, int low) => _text('High $high°  •  Low $low°',
      'Máx. $high°  •  Mín. $low°', 'Max. $high°  •  Min. $low°');
  String get wind => _text('Wind', 'Viento', 'Vent');
  String get average => _text('Average', 'Promedio', 'Moyenne');
  String get weatherDescriptionTitle =>
      _text('Conditions', 'Condiciones', 'Conditions');
  String radarLayerLabel(Object layer) {
    final name = layer.toString().split('.').last;
    return switch (name) {
      'precipitation' => precipitation,
      'clouds' => _text('Clouds', 'Nubes', 'Nuages'),
      'temperature' => _text('Temperature', 'Temperatura', 'Température'),
      'wind' => wind,
      _ => name,
    };
  }

  String radarLegendLow(Object layer) {
    final name = layer.toString().split('.').last;
    return switch (name) {
      'precipitation' => _text('Light', 'Ligera', 'Légère'),
      'clouds' => _text('Clear', 'Despejado', 'Dégagé'),
      'temperature' => _text('Cold', 'Frío', 'Froid'),
      'wind' => _text('Calm', 'Calmado', 'Calme'),
      _ => '',
    };
  }

  String radarLegendHigh(Object layer) {
    final name = layer.toString().split('.').last;
    return switch (name) {
      'precipitation' => _text('Heavy', 'Intensa', 'Forte'),
      'clouds' => _text('Overcast', 'Cubierto', 'Couvert'),
      'temperature' => _text('Hot', 'Caliente', 'Chaud'),
      'wind' => _text('Strong', 'Fuerte', 'Fort'),
      _ => '',
    };
  }

  String savedLocationsCount(int count) => count == 1
      ? _text('1 saved location', '1 ubicación guardada', '1 lieu enregistré')
      : _text('$count saved locations', '$count ubicaciones guardadas',
          '$count lieux enregistrés');

  String weatherUpdateTitle(String city) => _text('Weather update for $city',
      'Actualización del tiempo para $city', 'Mise à jour météo pour $city');
  String localizeChangeDescription(String change) {
    var result = change.replaceFirstMapped(
        RegExp(r'Temperature jumped to ([0-9-]+)°C'),
        (m) => _text(
            'Temperature jumped to ${m[1]}°C',
            'La temperatura subió a ${m[1]}°C',
            'La température est montée à ${m[1]}°C'));
    result = result.replaceFirstMapped(
        RegExp(r'Temperature dropped to ([0-9-]+)°C'),
        (m) => _text(
            'Temperature dropped to ${m[1]}°C',
            'La temperatura bajó a ${m[1]}°C',
            'La température est descendue à ${m[1]}°C'));
    result =
        result.replaceFirst('Now ', _text('Now ', 'Ahora ', 'Maintenant '));
    return result;
  }

  String localizeError(String? error) {
    final value = (error ?? '').trim();
    if (value.isEmpty) {
      return pleaseTryAgain;
    }
    if (value == 'Something went wrong. Please try again.') {
      return somethingWentWrong;
    }
    if (value == 'City not found. Check the spelling and try again.') {
      return _text(
          'City not found. Check the spelling and try again.',
          'Ciudad no encontrada. Revisa la ortografía e inténtalo de nuevo.',
          'Ville introuvable. Vérifiez l’orthographe et réessayez.');
    }
    if (value == 'Invalid API key. Check your .env file.') {
      return _text(
          'Invalid API key. Check your .env file.',
          'Clave API no válida. Comprueba tu archivo .env.',
          'Clé API invalide. Vérifiez votre fichier .env.');
    }
    if (value == 'Network error: could not reach the weather service.') {
      return _text(
          'Network error: could not reach the weather service.',
          'Error de red: no se pudo conectar con el servicio meteorológico.',
          'Erreur réseau : impossible de joindre le service météo.');
    }
    if (value.startsWith('Failed to load weather')) {
      return _text(value, 'No se pudo cargar el tiempo.',
          'Impossible de charger la météo.');
    }
    if (value.startsWith('Failed to load forecast')) {
      return _text(value, 'No se pudo cargar el pronóstico.',
          'Impossible de charger les prévisions.');
    }
    return value;
  }

  String greetingForHour(int hour, String name) {
    final period = hour < 5
        ? _text('Good night', 'Buenas noches', 'Bonne nuit')
        : hour < 12
            ? _text('Good morning', 'Buenos días', 'Bonjour')
            : hour < 17
                ? _text('Good afternoon', 'Buenas tardes', 'Bon après-midi')
                : hour < 21
                    ? _text('Good evening', 'Buenas tardes', 'Bonsoir')
                    : _text('Good night', 'Buenas noches', 'Bonne nuit');
    return '$period, $name';
  }

  String weatherDescription(String description) {
    final normalized = description.trim().toLowerCase();
    final translation = switch (normalized) {
      'clear sky' => _text('clear sky', 'cielo despejado', 'ciel dégagé'),
      'few clouds' => _text('few clouds', 'pocas nubes', 'quelques nuages'),
      'scattered clouds' =>
        _text('scattered clouds', 'nubes dispersas', 'nuages épars'),
      'broken clouds' =>
        _text('broken clouds', 'nubes fragmentadas', 'nuages fragmentés'),
      'overcast clouds' =>
        _text('overcast clouds', 'nubes cubiertas', 'ciel couvert'),
      'light rain' => _text('light rain', 'lluvia ligera', 'pluie légère'),
      'moderate rain' =>
        _text('moderate rain', 'lluvia moderada', 'pluie modérée'),
      'heavy intensity rain' =>
        _text('heavy intensity rain', 'lluvia intensa', 'fortes pluies'),
      'shower rain' => _text('shower rain', 'lluvia de chubascos', 'averses'),
      'rain' => _text('rain', 'lluvia', 'pluie'),
      'thunderstorm' => _text('thunderstorm', 'tormenta eléctrica', 'orage'),
      'light snow' => _text('light snow', 'nieve ligera', 'neige légère'),
      'snow' => _text('snow', 'nieve', 'neige'),
      'mist' => _text('mist', 'neblina', 'brume'),
      'fog' => _text('fog', 'niebla', 'brouillard'),
      'haze' => _text('haze', 'calima', 'brume sèche'),
      _ => description.trim(),
    };
    if (translation.isEmpty) return translation;
    return translation[0].toUpperCase() + translation.substring(1);
  }
}
