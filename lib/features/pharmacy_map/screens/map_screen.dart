import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';

class Pharmacy {
  final String id;
  final String name;
  final double lat;
  final double lng;
  final String address;
  final String phone;
  final String openHours;
  double? distance; // in km

  Pharmacy({
    required this.id,
    required this.name,
    required this.lat,
    required this.lng,
    required this.address,
    required this.phone,
    required this.openHours,
    this.distance,
  });

  bool get isOpen {
    final now = DateTime.now();
    final hour = now.hour;
    
    // Parse jam buka (format: "HH:MM - HH:MM" atau "24 Jam")
    if (openHours == "24 Jam") return true;
    
    try {
      final parts = openHours.split(' - ');
      if (parts.length != 2) return false;
      
      final openTime = int.parse(parts[0].split(':')[0]);
      final closeTime = int.parse(parts[1].split(':')[0]);
      
      return hour >= openTime && hour < closeTime;
    } catch (e) {
      return false;
    }
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // Map controller
  final MapController _mapController = MapController();
  
  // User location
  Position? _currentPosition;
  bool _isLoading = true;
  String _searchQuery = '';

  // Default location (UPN Yogyakarta)
  static const LatLng _defaultLocation = LatLng(-7.761005, 110.409156);

  // Data Apotek (Area Yogyakarta - Real Coordinates)
  final List<Pharmacy> _allPharmacies = [
    Pharmacy(
      id: '1',
      name: 'Apotek K-24 Seturan Sleman',
      lat: -7.767720,
      lng: 110.410123,
      address: 'Jl. Seturan Raya No.101A, Kledokan, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0895-3683-44424',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '2',
      name: 'Apotek K-24 Babarsari Sleman',
      lat: -7.781879,
      lng: 110.414104,
      address: 'Jl. Babarsari No.13 B, Janti, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0813-9452-0000',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '3',
      name: 'Apotek Pas 24 Jam Jalan Kaliurang',
      lat: -7.759873,
      lng: 110.380883,
      address: 'Jl. Kaliurang No.Km. 5,2, Karang Wuni, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55284',
      phone: '0816-244-667',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '4',
      name: 'Apotek K-24 Raya Janti Bantul',
      lat: -7.798476,
      lng: 110.409021,
      address: 'Jl. Raya Janti, Modalan, Banguntapan, Kec. Banguntapan, Kabupaten Bantul, Daerah Istimewa Yogyakarta 55198',
      phone: '0821-3627-6253',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '5',
      name: 'Apotek K24 Ambarukmo',
      lat: -7.783109,
      lng: 110.397403,
      address: 'Jl. Laksda Adisucipto No.150 A, Papringan, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0813-5823-6010',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '6',
      name: 'Apotek K-24 Demangan Baru Yogyakarta',
      lat: -7.778547,
      lng: 110.393288,
      address: 'Jl. Demangan Baru, Demangan Baru, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0895-3230-90889',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '7',
      name: 'Apotek Kimia Farma Adi Sucipto',
      lat: -7.783449,
      lng: 110.398764,
      address: 'Jl. Laksda Adisucipto No.63 A, Ambarukmo, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0812-2812-9992',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '8',
      name: 'Apotek Kimia Farma Seturan',
      lat: -7.765443,
      lng: 110.409762,
      address: 'Jl. Seturan Raya No.C/3B, Kledokan, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0811-1067-8229',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '9',
      name: 'Apotek K-24 Nologaten Sleman',
      lat: -7.770127,
      lng: 110.401802,
      address: 'Jl. Wahid Hasyim, Dabag, Condongcatur, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0812-1149-2516',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '10',
      name: 'Apotek K-24 Timoho Yogyakarta',
      lat: -7.790581,
      lng: 110.393535,
      address: 'Jl. Timoho RUKO No.315, Baciro, Kec. Gondokusuman, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55225',
      phone: '0813-2970-7067',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '11',
      name: 'Apotek K-24 Gejayan',
      lat: -7.770791,
      lng: 110.389935,
      address: 'Jl. Affandi No.29, Santren, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0896-7464-8483',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '12',
      name: 'Apotek Pharm 24 Waringin',
      lat: -7.797176,
      lng: 110.377762,
      address: 'Jl. Doktor Sutomo No.2, Baciro, Kec. Gondokusuman, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55211',
      phone: '0821-3177-1102',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '13',
      name: 'Apotek Kimia Farma Maguwo',
      lat: -7.783355,
      lng: 110.430369,
      address: 'Jl. Raya Solo - Yogyakarta, Kembang, Maguwoharjo, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55282',
      phone: '0895-7011-28448',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '14',
      name: 'Apotek Srikandi',
      lat: -7.783355,
      lng: 110.413145,
      address: 'Ruko Permata, Blok R, Jl. Babarsari No.3A, Tambak Bayan, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '(0274) 484500',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '15',
      name: 'Apotek K 24 Kusumanegara',
      lat: -7.802066,
      lng: 110.389296,
      address: 'Jl. Kusumanegara No.86, Warungboto, Kec. Umbulharjo, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55165',
      phone: '0851-0010-2424',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '16',
      name: 'Apotek Kimia Farma Colombo',
      lat: -7.777567,
      lng: 110.386058,
      address: 'Jl. Colombo No.1, Karang Malang, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0811-1067-8220',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '17',
      name: 'Apotek K-24 Anggajaya Sleman',
      lat: -7.754008,
      lng: 110.397073,
      address: 'Jl. Anggajaya 1 No.188, Gejayan, Condongcatur, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55283',
      phone: '0813-2517-7836',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '18',
      name: 'Apotek K-24 Jl. Kaliurang Sleman',
      lat: -7.762987,
      lng: 110.379538,
      address: 'No.KM. 5 / 94, Jl. Kaliurang, Kocoran, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0823-2955-9171',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '19',
      name: 'Apotek K-24 Gajah Mada Yogyakarta',
      lat: -7.801128,
      lng: 110.373116,
      address: '08, Jl. Gajah Mada No.7C, Purwokinanti, Pakualaman, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55166',
      phone: '0831-0573-9989',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '20',
      name: 'Apotek K-24 Condong Catur Sleman',
      lat: -7.755317,
      lng: 110.409774,
      address: 'Jl. Nusa Indah No.408, Dero, Condongcatur, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0895-2754-2824',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '21',
      name: 'Apotek K-24 Jl. Magelang Yogyakarta',
      lat: -7.774106,
      lng: 110.361463,
      address: 'Jalan Magelang No.160-162 Kricak, Karangwaru, Kec. Tegalrejo, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55241',
      phone: '0813-2581-7725',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '22',
      name: 'Apotek K-24 Gondomanan Yogyakarta',
      lat: -7.807985,
      lng: 110.369611,
      address: 'Jl. Brigjen Katamso No.117, Prawirodirjan, Kec. Gondomanan, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55131',
      phone: '0821-1450-204',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '23',
      name: 'Apotek K-24 Kotabaru',
      lat: -7.789355,
      lng: 110.369497,
      address: 'Jl. Ahmad Jazuli No.1, Kotabaru, Kec. Gondokusuman, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55224',
      phone: '0851-0011-2424',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '24',
      name: 'Apotek K-24 Karanglo Yogyakarta',
      lat: -7.827516,
      lng: 110.400752,
      address: 'Jl. Karanglo No.5 C, Purbayan, Kec. Kotagede, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55172',
      phone: '0813-9240-2264',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '25',
      name: 'Apotek Kimia Farma Malioboro',
      lat: -7.792687,
      lng: 110.365713,
      address: 'Jl. Malioboro No.123, Sosromenduran, Gedong Tengen, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55271',
      phone: '0822-6441-3643',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '26',
      name: 'Apotek Kimia Farma Jakal',
      lat: -7.752995,
      lng: 110.384783,
      address: 'Jl. Kaliurang No.48, Manggung, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0811-1067-8326',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '27',
      name: 'Apotek K-24 Tamansiswa Yogyakarta',
      lat: -7.811965,
      lng: 110.376920,
      address: 'Jl. Taman Siswa No.109, Wirogunan, Kec. Mergangsan, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55151',
      phone: '0821-3790-3560',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '28',
      name: 'Apotek K-24 Kentungan Sleman',
      lat: -7.750087,
      lng: 110.386242,
      address: 'Jalan Kaliurang Km. 6, Blok A No.15 5, Kentungan, Condongcatur, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55283',
      phone: '0858-4875-4745',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '29',
      name: 'Apotek K-24 Jl. Parangtritis Yogyakarta',
      lat: -7.826052,
      lng: 110.367000,
      address: 'Jl. Parangtritis No.172B, Mantrijeron, Kec. Mantrijeron, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55188',
      phone: '0851-1103-2039',
      openHours: '24 Jam',
    ),
    Pharmacy(
      id: '30',
      name: 'Apotek Anugerah24 - Babarsari',
      lat: -7.774515,
      lng: 110.415627,
      address: 'Jl. Babarsari No.88, Tambak Bayan, Caturtunggal, Kec. Depok, Kabupaten Sleman, Daerah Istimewa Yogyakarta 55281',
      phone: '0896-0315-7888',
      openHours: '07:00 - 22:00',
    ),
    Pharmacy(
      id: '31',
      name: 'Apotek K-24 Wirosaban Yogyakarta',
      lat: -7.824852,
      lng: 110.380570,
      address: 'Jl. Sorogenen Jl. Nitikan Baru No.240 No.19 Kp, Sorosutan, Kec. Umbulharjo, Kota Yogyakarta, Daerah Istimewa Yogyakarta 55162',
      phone: '0889-8389-0901',
      openHours: '24 Jam',
    ),
  ];

  List<Pharmacy> _pharmacies = [];

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  // Get Current Location
  Future<void> _initializeLocation() async {
    setState(() => _isLoading = true);

    try {
      // Request location permission
      final permission = await Permission.location.request();
      
      if (permission.isGranted) {
        // Get current position
        final position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
        );

        setState(() {
          _currentPosition = position;
        });

        // Calculate distances and sort
        _updatePharmacyDistances();

        // Move camera to user location
        _mapController.move(
          LatLng(position.latitude, position.longitude),
          14.5,
        );
      } else {
        // Permission denied, use default location
        _updatePharmacyDistances();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Izin lokasi ditolak. Menggunakan lokasi default.'),
              backgroundColor: Colors.orange,
            ),
          );
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      _updatePharmacyDistances();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mendapatkan lokasi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Calculate Distance
  double _calculateDistance(double lat, double lng) {
    if (_currentPosition == null) {
      // Use default location (UPN Yogyakarta)
      return Geolocator.distanceBetween(
        _defaultLocation.latitude,
        _defaultLocation.longitude,
        lat,
        lng,
      ) / 1000; // Convert to km
    }

    return Geolocator.distanceBetween(
      _currentPosition!.latitude,
      _currentPosition!.longitude,
      lat,
      lng,
    ) / 1000; // Convert to km
  }

  // Update Pharmacy Distances & Sort
  void _updatePharmacyDistances() {
    for (var pharmacy in _allPharmacies) {
      pharmacy.distance = _calculateDistance(pharmacy.lat, pharmacy.lng);
    }

    // Sort by distance (nearest first)
    _allPharmacies.sort((a, b) => (a.distance ?? 0).compareTo(b.distance ?? 0));

    // Filter by search query
    _filterPharmacies();
  }

  // Filter Pharmacies by Search
  void _filterPharmacies() {
    setState(() {
      if (_searchQuery.isEmpty) {
        _pharmacies = List.from(_allPharmacies);
      } else {
        _pharmacies = _allPharmacies
            .where((p) => p.name.toLowerCase().contains(_searchQuery.toLowerCase()))
            .toList();
      }
    });
  }

  // Go to My Location
  Future<void> _goToMyLocation() async {
    if (_currentPosition != null) {
      _mapController.move(
        LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
        15.0,
      );
    } else {
      await _initializeLocation();
    }
  }

  // Open in Google Maps
  Future<void> _openInGoogleMaps(Pharmacy pharmacy) async {
    // Try multiple URL schemes for better compatibility
    final urls = [
      // 1. Google Maps app (geo: scheme)
      Uri.parse('geo:0,0?q=${pharmacy.lat},${pharmacy.lng}(${Uri.encodeComponent(pharmacy.name)})'),
      
      // 2. Google Maps web (fallback)
      Uri.parse(
        'https://www.google.com/maps/dir/?api=1'
        '&destination=${pharmacy.lat},${pharmacy.lng}'
        '&travelmode=driving',
      ),
    ];

    bool launched = false;
    String? errorMessage;

    for (var url in urls) {
      try {
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
          launched = true;
          break;
        }
      } catch (e) {
        errorMessage = e.toString();
        print('Error launching $url: $e');
        continue;
      }
    }

    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            errorMessage != null 
              ? 'Error: $errorMessage'
              : 'Tidak dapat membuka Google Maps. Pastikan Google Maps terinstall.',
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. FLUTTER MAP (OpenStreetMap)
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _currentPosition != null
                  ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
                  : _defaultLocation,
              initialZoom: 14.5,
              minZoom: 10.0,
              maxZoom: 18.0,
            ),
            children: [
              // Tile Layer (OpenStreetMap)
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.PillPal',
                maxZoom: 19,
              ),
              
              // Marker Layer (Pharmacies)
              MarkerLayer(
                markers: [
                  // User location marker (blue)
                  if (_currentPosition != null)
                    Marker(
                      point: LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
                      width: 40,
                      height: 40,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.3),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.blue, width: 3),
                        ),
                        child: const Icon(Icons.person, color: Colors.blue, size: 20),
                      ),
                    ),
                  
                  // Pharmacy markers
                  ..._pharmacies.map((pharmacy) {
                    return Marker(
                      point: LatLng(pharmacy.lat, pharmacy.lng),
                      width: 40,
                      height: 40,
                      child: GestureDetector(
                        onTap: () {
                          // Zoom to pharmacy
                          _mapController.move(
                            LatLng(pharmacy.lat, pharmacy.lng),
                            16.0,
                          );
                          
                          // Show info
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${pharmacy.name}\n${pharmacy.distance?.toStringAsFixed(1)} km • ${pharmacy.isOpen ? "Buka" : "Tutup"}',
                              ),
                              duration: const Duration(seconds: 2),
                              backgroundColor: pharmacy.isOpen ? Colors.green : Colors.red,
                            ),
                          );
                        },
                        child: Icon(
                          Icons.local_pharmacy,
                          color: pharmacy.isOpen ? Colors.green : Colors.red,
                          size: 40,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),

          // Loading overlay
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
                ),
              ),
            ),

          // 2. FLOATING SEARCH BAR (ATAS)
          Positioned(
            top: 50,
            left: 20,
            right: 20,
            child: Container(
              height: 55,
              padding: const EdgeInsets.symmetric(horizontal: 15),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10, offset: Offset(0, 5))],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black54),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      decoration: const InputDecoration(
                        hintText: "Cari Apotek Terdekat...",
                        border: InputBorder.none,
                      ),
                      onChanged: (value) {
                        setState(() => _searchQuery = value);
                        _filterPharmacies();
                      },
                    ),
                  ),
                  const Icon(Icons.search, color: Colors.teal),
                ],
              ),
            ),
          ),

          // 3. MY LOCATION BUTTON (KANAN ATAS)
          Positioned(
            top: 120,
            right: 20,
            child: FloatingActionButton(
              mini: true,
              backgroundColor: Colors.white,
              onPressed: _goToMyLocation,
              child: const Icon(Icons.my_location, color: Colors.teal),
            ),
          ),

          // 4. HORIZONTAL CARD SLIDER (BAWAH)
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: SizedBox(
              height: 130,
              child: _pharmacies.isEmpty
                  ? Center(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 20),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                        ),
                        child: const Text(
                          'Tidak ada apotek ditemukan',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ),
                    )
                  : ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 15),
                      itemCount: _pharmacies.length,
                      itemBuilder: (context, index) {
                        final pharmacy = _pharmacies[index];
                        return GestureDetector(
                          onTap: () {
                            _mapController.move(
                              LatLng(pharmacy.lat, pharmacy.lng),
                              16.0,
                            );
                          },
                          child: Container(
                            width: 300,
                            margin: const EdgeInsets.only(right: 15),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 10)],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: Colors.teal.shade50,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.local_pharmacy, color: Colors.teal, size: 26),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pharmacy.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 3),
                                          Text(
                                            "${pharmacy.distance?.toStringAsFixed(1)} km • ${pharmacy.isOpen ? 'Buka' : 'Tutup'}",
                                            style: TextStyle(
                                              color: pharmacy.isOpen ? Colors.green : Colors.red,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  pharmacy.address,
                                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        pharmacy.openHours,
                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                      ),
                                    ),
                                    ElevatedButton(
                                      onPressed: () => _openInGoogleMaps(pharmacy),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.teal,
                                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text(
                                        'Navigasi',
                                        style: TextStyle(fontSize: 11, color: Colors.white),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
