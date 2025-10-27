import 'package:flutter/material.dart';

class EditProfilePage extends StatefulWidget {
  final String title;
  final String initialValue;
  final String fieldType; // 'name', 'email', 'phone', 'description'

  const EditProfilePage({
    super.key,
    required this.title,
    required this.initialValue,
    required this.fieldType,
  });

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _descriptionController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: 'Kotik Milo');
    _emailController = TextEditingController(text: 'Kotik@chip.ma');
    _phoneController = TextEditingController(text: '777-777-777');
    _descriptionController = TextEditingController(text: 'I love KitKat');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Ред. Профиль',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Аватар с кнопкой редактирования
            Stack(
              children: [
                CircleAvatar(
                  radius: 50,
                  backgroundImage: const AssetImage('assets/icons/avatar.png'),
                  backgroundColor: Colors.grey[300],
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // ФИО
            _buildTextField(
              label: 'ФИО',
              controller: _nameController,
            ),

            const SizedBox(height: 16),

            // EMAIL
            _buildTextField(
              label: 'EMAIL',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),

            const SizedBox(height: 16),

            // НОМЕР
            _buildTextField(
              label: 'НОМЕР',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
            ),

            const SizedBox(height: 16),

            // ОПИСАНИЕ
            _buildTextField(
              label: 'ОПИСАНИЕ',
              controller: _descriptionController,
              maxLines: 4,
            ),

            const SizedBox(height: 32),

            // Кнопка сохранить
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Сохранить данные
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'СОХРАНИТЬ',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}