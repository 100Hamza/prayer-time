import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class GpsPrayerTimesPage extends StatefulWidget {
  const GpsPrayerTimesPage({super.key});

  @override
  State<GpsPrayerTimesPage> createState() => _GpsPrayerTimesPageState();
}

class _GpsPrayerTimesPageState extends State<GpsPrayerTimesPage> {
  PrayerTimes? prayerTimes;
  Madhab selectedMadhab = Madhab.hanafi;
  bool isLoading = true;
  String errorMessage = "";
  Position? currentPosition;

  @override
  void initState() {
    super.initState();
    _getPrayerTimes();
  }

  Future<void> _getPrayerTimes() async {
    setState(() {
      isLoading = true;
      errorMessage = "";
    });

    try {
      var permissionStatus = await _checkLocationPermission();
      if (!permissionStatus) return;

      currentPosition = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );

      // Calculate prayer times based on location
      await _computePrayerTimes(
        latitude: currentPosition!.latitude,
        longitude: currentPosition!.longitude,
      );
    } catch (e) {
      setState(() {
        errorMessage = "Unable to get location:\n$e";
        isLoading = false;
      });
    }
  }

  Future<bool> _checkLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        errorMessage =
            "Location access is blocked.\nPlease enable it in your phone settings.";
        isLoading = false;
      });
      return false;
    }

    if (permission == LocationPermission.denied) {
      setState(() {
        errorMessage = "Location permission required";
        isLoading = false;
      });
      return false;
    }

    return true;
  }

  Future<void> _computePrayerTimes({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final today = DateTime.now();
      final location = Coordinates(latitude, longitude);

      // Karachi method can be replaced with any preferred method it can be done on the basis of the coorindates
      final calculationParams = CalculationMethodParameters.karachi();
      calculationParams.madhab = selectedMadhab;
      calculationParams.highLatitudeRule = HighLatitudeRule.twilightAngle;

      prayerTimes = PrayerTimes(
        coordinates: location,
        date: today,
        calculationParameters: calculationParams,
        precision: true,
      );

      setState(() => isLoading = false);
    } catch (e) {
      setState(() {
        errorMessage = "Couldn't calculate prayer times: $e";
        isLoading = false;
      });
    }
  }

  String _getFormattedTime(DateTime? utcTime) {
    if (utcTime == null) return "--:--";
    final localTime = utcTime.toLocal();
    return TimeOfDay.fromDateTime(localTime).format(context);
  }

  String _getPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return "Fajr";
      case Prayer.dhuhr:
        return "Dhuhr";
      case Prayer.asr:
        return "Asr";
      case Prayer.maghrib:
        return "Maghrib";
      case Prayer.isha:
        return "Isha";
      case Prayer.sunrise:
        return "Sunrise";
      default:
        return prayer.toString().split('.').last;
    }
  }

  Widget _buildPrayerCard(String prayerName, DateTime? time) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Text(
            prayerName.substring(0, 1),
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ),
        title: Text(
          prayerName,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: Text(
          _getFormattedTime(time),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.green,
          ),
        ),
      ),
    );
  }

  Widget _buildMadhabSelector() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Calculation Method",
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMadhabChip("Hanafi", Madhab.hanafi),
              const SizedBox(width: 12),
              _buildMadhabChip("Shafi'i", Madhab.shafi),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMadhabChip(String label, Madhab madhab) {
    final isSelected = selectedMadhab == madhab;
    return GestureDetector(
      onTap: () {
        if (!isSelected) {
          setState(() => selectedMadhab = madhab);
          _getPrayerTimes();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey[300]!,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey[700],
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationInfo() {
    if (currentPosition == null) return Container();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.location_on, color: Colors.blue[600], size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              "Lat: ${currentPosition!.latitude.toStringAsFixed(4)}, "
              "Lng: ${currentPosition!.longitude.toStringAsFixed(4)}",
              style: TextStyle(
                fontSize: 13,
                color: Colors.blue[800],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off, size: 64, color: Colors.orange[400]),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _getPrayerTimes,
              icon: const Icon(Icons.refresh),
              label: const Text("Try Again"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList() {
    Prayer? currentPrayer = prayerTimes?.currentPrayer(date: DateTime.now());
    Prayer? nextPrayer = prayerTimes?.nextPrayer(date: DateTime.now());
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(20),
      ),
      child: SingleChildScrollView(
        child: Column(
          children: [
            _buildLocationInfo(),
            Text('Current: ${_getPrayerName(currentPrayer!)}'),
            Text('Next: ${_getPrayerName(nextPrayer!)}'),
            _buildPrayerCard("Fajr", prayerTimes?.fajr),
            _buildPrayerCard("Sunrise", prayerTimes?.sunrise),
            _buildPrayerCard("Dhuhr", prayerTimes?.dhuhr),
            _buildPrayerCard("Asr", prayerTimes?.asr),
            _buildPrayerCard("Maghrib", prayerTimes?.maghrib),
            _buildPrayerCard("Isha", prayerTimes?.isha),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Prayer Times"),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: isLoading ? null : _getPrayerTimes,
            tooltip: "Refresh",
          ),
        ],
      ),
      body: isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    "Getting your location...",
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : errorMessage.isNotEmpty
          ? _buildErrorView()
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildMadhabSelector(),
                  const SizedBox(height: 20),
                  Expanded(child: _buildPrayerTimesList()),
                  const SizedBox(height: 8),
                  Text(
                    "Times are displayed in your local timezone",
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
    );
  }
}
