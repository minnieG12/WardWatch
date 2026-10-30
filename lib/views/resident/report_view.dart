import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../services/database_service.dart';
import '../../widgets/screen_wrapper.dart';

class ReportView extends StatefulWidget {
  const ReportView({super.key});

  @override
  State<ReportView> createState() => _ReportViewState();
}

class _ReportViewState extends State<ReportView> {
  final _dbService = DatabaseService();
  final _supabase = Supabase.instance.client;

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _landmarkController = TextEditingController();

  int? _selectedCategory;
  XFile? _imageFile;
  Position? _currentPosition;
  bool _isLoading = false;

  List<Map<String, dynamic>> _dbCategories = [];
  bool _isLoadingCategories = true;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      final data = await _supabase.from('categories').select('id, category_name').order('id');
      if (mounted) {
        setState(() {
          _dbCategories = data;
          _isLoadingCategories = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching categories: $e');
      if (mounted) setState(() => _isLoadingCategories = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.camera, imageQuality: 70);
    if (image != null) setState(() => _imageFile = image);
  }

  Future<void> _getLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enable Location Services.')));
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }

    Position position = await Geolocator.getCurrentPosition();
    setState(() => _currentPosition = position);
  }

  Future<void> _submit() async {
    // 1. Mandatory Location Check
    bool hasGPS = _currentPosition != null;
    bool hasLandmark = _landmarkController.text.trim().isNotEmpty;

    if (_selectedCategory == null || _imageFile == null || _titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill all required fields and add a photo!'), backgroundColor: Color(0xFFBE1C2E)));
      return;
    }

    if (!hasGPS && !hasLandmark) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Location Required: Please pin GPS or enter a nearby landmark.'), backgroundColor: Color(0xFFBE1C2E)));
      return;
    }

    setState(() => _isLoading = true);
    try {
      final bytes = await _imageFile!.readAsBytes();

      await _dbService.submitReport(
        categoryId: _selectedCategory!,
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        // Send 0.0 if GPS is missing, but Landmark is present
        latitude: hasGPS ? _currentPosition!.latitude : 0.0,
        longitude: hasGPS ? _currentPosition!.longitude : 0.0,
        landmark: _landmarkController.text.trim(),
        imageBytes: bytes,
        fileName: _imageFile!.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report Submitted Successfully!'), backgroundColor: Color(0xFF055391)));
        Navigator.pop(context); // Returns to Dashboard
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Submission Error: $e'), backgroundColor: const Color(0xFFBE1C2E)));
    }
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ScreenWrapper(
      backgroundPath: 'assets/images/app_bg.png',
      useBlur: false,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('File a Report', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: const Color(0xFF055391),
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        body: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 8,
                color: Colors.white.withOpacity(0.98),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Issue Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF055391))),
                      const Divider(height: 32),

                      _isLoadingCategories
                          ? const Center(child: CircularProgressIndicator())
                          : DropdownButtonFormField<int>(
                        decoration: _inputStyle('Select Category', Icons.category),
                        value: _selectedCategory,
                        items: _dbCategories.map((cat) => DropdownMenuItem<int>(
                            value: cat['id'],
                            child: Text(cat['category_name'])
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedCategory = val),
                      ),
                      const SizedBox(height: 20),

                      TextField(controller: _titleController, decoration: _inputStyle('Short Title (e.g., Deep Pothole)', Icons.title)),
                      const SizedBox(height: 20),

                      TextField(
                        controller: _descController,
                        maxLines: 4,
                        decoration: _inputStyle('Detailed Description', Icons.description).copyWith(alignLabelWithHint: true),
                      ),
                      const SizedBox(height: 32),

                      const Text('Evidence & Location', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF055391))),
                      const Divider(height: 32),

                      Row(
                        children: [
                          Expanded(child: _buildActionButton(
                            icon: Icons.camera_alt,
                            label: _imageFile == null ? 'Attach Photo' : 'Photo Attached',
                            isComplete: _imageFile != null,
                            onTap: _pickImage,
                          )),
                          const SizedBox(width: 16),
                          Expanded(child: _buildActionButton(
                            icon: Icons.location_on,
                            label: _currentPosition == null ? 'Pin GPS location (Optional)' : 'GPS Pinned',
                            isComplete: _currentPosition != null,
                            onTap: _getLocation,
                          )),
                        ],
                      ),

                      const SizedBox(height: 16),
                      TextField(
                        controller: _landmarkController,
                        decoration: _inputStyle('Nearby Landmark (Required if no GPS)', Icons.place),
                      ),

                      const SizedBox(height: 40),

                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFBE1C2E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('SUBMIT REPORT', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.2)),
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputStyle(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: const Color(0xFF055391)),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF055391), width: 2)),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required bool isComplete, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isComplete ? const Color(0xFF055391).withOpacity(0.1) : Colors.transparent,
          border: Border.all(color: isComplete ? const Color(0xFF055391) : Colors.grey.shade400, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(isComplete ? Icons.check_circle : icon, color: isComplete ? const Color(0xFF055391) : Colors.grey.shade600, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: isComplete ? const Color(0xFF055391) : Colors.grey.shade600, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}