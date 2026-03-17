/// Custom Google Maps style — orange, green & grey modern theme.
/// Apply via `GoogleMap(style: FlaRideMapStyle.json, …)` or
/// `controller.setMapStyle(FlaRideMapStyle.json)`.
class FlaRideMapStyle {
  FlaRideMapStyle._();

  static const String json = '''
[
  {
    "elementType": "geometry",
    "stylers": [{ "color": "#f5f5f5" }]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#6b6b6b" }]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{ "color": "#ffffff" }]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{ "color": "#c9c9c9" }]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#9e9e9e" }]
  },
  {
    "featureType": "landscape",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#eaeaea" }]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#e0e8d8" }]
  },
  {
    "featureType": "landscape.natural.terrain",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#d6dec8" }]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{ "color": "#dde4d0" }]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#7a7a7a" }]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#c8dbb0" }]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#5a7a3a" }]
  },
  {
    "featureType": "road",
    "elementType": "geometry",
    "stylers": [{ "color": "#ffffff" }]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#8a8a8a" }]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#fce8d2" }]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry.stroke",
    "stylers": [{ "color": "#f0d0a8" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#f5c589" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{ "color": "#e8a84c" }]
  },
  {
    "featureType": "road.highway",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#6b5a3a" }]
  },
  {
    "featureType": "road.local",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#f9f9f9" }]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{ "color": "#e0e0e0" }]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#8a8a8a" }]
  },
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [{ "color": "#c4d7d1" }]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{ "color": "#7a9a8a" }]
  }
]
''';
}
