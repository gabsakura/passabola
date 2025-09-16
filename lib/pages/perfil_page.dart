import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:passaabola/pages/login_page.dart';
import '../data/constants.dart';
import 'dart:io';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  String? _userId; // UID do usuário atual
  bool _isLoading = false;
  bool _isRegistered = false;
  bool _isCheckingRegistration = true;
  Map<String, dynamic>? _userData; // Dados completos do usuário
  String? _profileImageUrl; // URL da foto de perfil
  bool _notificationsEnabled = true; // Configuração de notificações
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _checkUserRegistration();
    _loadNotificationSettings();
  }

  Future<void> _checkUserRegistration() async {
    try {
      // Obter o UID do usuário atual do Firebase Auth
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        _userId = user.uid;

        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('jogadoras')
            .doc(_userId!)
            .get();

        if (userDoc.exists && userDoc.data() != null) {
          final data = userDoc.data() as Map<String, dynamic>;
          setState(() {
            _isRegistered = data['isRegistered'] ?? false;
            _userData = data;
            _profileImageUrl = data['profileImageUrl'];
            _isCheckingRegistration = false;
          });
        } else {
          setState(() {
            _isRegistered = false;
            _userData = null;
            _profileImageUrl = null;
            _isCheckingRegistration = false;
          });
        }
      } else {
        // Usuário não está logado, redirecionar para login
        setState(() {
          _isRegistered = false;
          _userData = null;
          _isCheckingRegistration = false;
        });
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      print('Erro ao buscar dados: $e');
      setState(() {
        _isRegistered = false;
        _userData = null;
        _isCheckingRegistration = false;
      });
    }
  }

  Future<void> _loadNotificationSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _notificationsEnabled = prefs.getBool('notifications_enabled') ?? true;
    });
  }

  Future<void> _saveNotificationSettings(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_enabled', enabled);
    setState(() {
      _notificationsEnabled = enabled;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KConstants.backgroundColor,
      body: _isCheckingRegistration || _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: KConstants.primaryColor),
            )
          : _isRegistered
          ? _buildRegisteredProfile()
          : _buildUnregisteredProfile(),
    );
  }

  Widget _buildRegisteredProfile() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // --- CABEÇALHO MODERNO COM GRADIENTE ---
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [KConstants.primaryColor, KConstants.secondaryColor],
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Stack(
              children: [
                // Decoração de fundo
                Positioned(
                  top: -50,
                  right: -50,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -30,
                  left: -30,
                  child: Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.1),
                    ),
                  ),
                ),

                // Conteúdo do cabeçalho
                SafeArea(
                  child: Padding(
                    padding: EdgeInsets.all(KConstants.spacingLarge),
                    child: Column(
                      children: [
                        // Botões superiores
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () => _showSettingsDialog(),
                              icon: const Icon(
                                Icons.settings,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                            IconButton(
                              onPressed: _logout,
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: KConstants.spacingMedium),

                        // Avatar com opção de editar
                        GestureDetector(
                          onTap: () => _showImagePickerOptions(),
                          child: Stack(
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                child: CircleAvatar(
                                  radius: 55,
                                  backgroundColor: Colors.white,
                                  child: CircleAvatar(
                                    radius: 50,
                                    backgroundColor: KConstants.primaryColor
                                        .withOpacity(0.1),
                                    backgroundImage: _profileImageUrl != null
                                        ? NetworkImage(_profileImageUrl!)
                                        : null,
                                    child: _profileImageUrl == null
                                        ? Icon(
                                            Icons.person,
                                            size: 50,
                                            color: KConstants.primaryColor,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  padding: EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: KConstants.primaryColor,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 2,
                                    ),
                                  ),
                                  child: Icon(
                                    Icons.camera_alt,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: KConstants.spacingMedium),

                        // Nome da jogadora
                        Text(
                          _userData?['name'] ?? 'Jogadora',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: KConstants.spacingSmall),

                        // Posição da jogadora
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: KConstants.spacingMedium,
                            vertical: KConstants.spacingSmall,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _userData?['position'] ?? 'Posição',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        SizedBox(height: KConstants.spacingLarge),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- INFORMAÇÕES DETALHADAS ---
          Padding(
            padding: EdgeInsets.all(KConstants.spacingLarge),
            child: Column(
              children: [
                // Card de informações pessoais
                _buildInfoCard(
                  icon: Icons.person_outline,
                  title: 'Informações Pessoais',
                  children: [
                    _buildInfoRow(
                      'Nome',
                      _userData?['name'] ?? 'Não informado',
                    ),
                    _buildInfoRow(
                      'Data de Nascimento',
                      _userData?['birthDate'] ?? 'Não informado',
                    ),
                    _buildInfoRow('CPF', _userData?['cpf'] ?? 'Não informado'),
                  ],
                ),

                SizedBox(height: KConstants.spacingLarge),

                // Card de contato
                _buildInfoCard(
                  icon: Icons.contact_phone,
                  title: 'Contato',
                  children: [
                    _buildInfoRow(
                      'Telefone',
                      _userData?['phone'] ?? 'Não informado',
                    ),
                    _buildInfoRow(
                      'Email',
                      FirebaseAuth.instance.currentUser?.email ??
                          'Não informado',
                    ),
                  ],
                ),

                SizedBox(height: KConstants.spacingLarge),

                // Card de localização
                _buildInfoCard(
                  icon: Icons.location_on,
                  title: 'Localização',
                  children: [
                    _buildInfoRow(
                      'Endereço',
                      _userData?['address'] ?? 'Não informado',
                    ),
                  ],
                ),

                SizedBox(height: KConstants.spacingLarge),

                // Card de estatísticas
                _buildInfoCard(
                  icon: Icons.analytics,
                  title: 'Estatísticas',
                  children: [
                    _buildInfoRow(
                      'Método de Cadastro',
                      _userData?['registrationMethod'] ?? 'Manual',
                    ),
                    _buildInfoRow(
                      'Data de Cadastro',
                      _formatDate(_userData?['registrationDate']),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // --- MENU DE AÇÕES ---
          Padding(
            padding: EdgeInsets.symmetric(horizontal: KConstants.spacingLarge),
            child: Column(
              children: [
                _buildActionButton(
                  icon: Icons.edit,
                  title: 'Editar Perfil',
                  subtitle: 'Atualizar suas informações',
                  onTap: () => _showEditProfileDialog(),
                ),
                SizedBox(height: KConstants.spacingMedium),
                _buildActionButton(
                  icon: Icons.notifications,
                  title: 'Notificações',
                  subtitle: 'Gerenciar alertas',
                  onTap: () {},
                ),
                SizedBox(height: KConstants.spacingMedium),
                _buildActionButton(
                  icon: Icons.privacy_tip,
                  title: 'Privacidade',
                  subtitle: 'Configurações de privacidade',
                  onTap: () {},
                ),
                SizedBox(height: KConstants.spacingLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnregisteredProfile() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(KConstants.spacingLarge),
        child: Column(
          children: [
            // --- CABEÇALHO ---
            SizedBox(height: 50),
            Icon(Icons.person_add, size: 80, color: KConstants.primaryColor),
            SizedBox(height: KConstants.spacingLarge),
            Text(
              "Complete seu perfil",
              style: KTextStyle.extraLargeTitleText,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: KConstants.spacingMedium),
            Text(
              "Para aproveitar ao máximo o app, complete suas informações de perfil",
              style: KTextStyle.bodyText,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: KConstants.spacingExtraLarge),

            // --- OPÇÕES DE CADASTRO ---
            _RegistrationOptionCard(
              icon: Icons.edit,
              title: "Cadastro Manual",
              description: "Preencha suas informações diretamente",
              onTap: () => _showManualRegistrationDialog(),
            ),
            SizedBox(height: KConstants.spacingLarge),
            _RegistrationOptionCard(
              icon: Icons.quiz,
              title: "Questionário",
              description: "Descubra sua posição ideal através de perguntas",
              onTap: () => _showQuizDialog(),
            ),
          ],
        ),
      ),
    );
  }

  void _showManualRegistrationDialog() {
    showDialog(
      context: context,
      builder: (context) => _ManualRegistrationDialog(onSave: _saveUserData),
    );
  }

  void _showQuizDialog() {
    showDialog(
      context: context,
      builder: (context) => _QuizDialog(onComplete: _saveUserDataFromQuiz),
    );
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('jogadoras')
          .doc(_userId!)
          .set({
            ...userData,
            'isRegistered': true,
            'registrationDate': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));

      setState(() {
        _isRegistered = true;
        _userData = userData;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil criado com sucesso!'),
          backgroundColor: KConstants.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar dados: $e'),
          backgroundColor: KConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _saveUserDataFromQuiz(String position) async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('jogadoras')
          .doc(_userId!)
          .set({
            'position': position,
            'isRegistered': true,
            'registrationDate': FieldValue.serverTimestamp(),
            'registrationMethod': 'quiz',
          }, SetOptions(merge: true));

      setState(() {
        _isRegistered = true;
        _userData = {'position': position, 'registrationMethod': 'quiz'};
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Perfil criado! Sua posição ideal é: $position'),
          backgroundColor: KConstants.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar dados: $e'),
          backgroundColor: KConstants.errorColor,
        ),
      );
    }
  }

  // Métodos auxiliares para o novo design
  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: EdgeInsets.all(KConstants.spacingLarge),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(KConstants.spacingSmall),
                decoration: BoxDecoration(
                  color: KConstants.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: KConstants.primaryColor, size: 20),
              ),
              SizedBox(width: KConstants.spacingMedium),
              Text(
                title,
                style: KTextStyle.titleText.copyWith(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SizedBox(height: KConstants.spacingMedium),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: KConstants.spacingSmall),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: KTextStyle.bodyText.copyWith(
                fontWeight: FontWeight.w500,
                color: KConstants.textSecondaryColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: KTextStyle.bodyText.copyWith(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(KConstants.spacingLarge),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: KConstants.primaryColor.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(KConstants.spacingMedium),
              decoration: BoxDecoration(
                color: KConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: KConstants.primaryColor, size: 24),
            ),
            SizedBox(width: KConstants.spacingLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: KTextStyle.titleText.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: KConstants.spacingExtraSmall),
                  Text(
                    subtitle,
                    style: KTextStyle.bodyText.copyWith(
                      color: KConstants.textSecondaryColor,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: KConstants.primaryColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'Não informado';

    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    }

    return 'Não informado';
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer logout: $e'),
          backgroundColor: KConstants.errorColor,
        ),
      );
    }
  }

  void _showImagePickerOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              // Opções apenas para mobile (não web)
              if (!kIsWeb) ...[
                ListTile(
                  leading: Icon(Icons.photo_library),
                  title: Text('Galeria'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromSource(ImageSource.gallery);
                  },
                ),
                ListTile(
                  leading: Icon(Icons.camera_alt),
                  title: Text('Câmera'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _pickImageFromSource(ImageSource.camera);
                  },
                ),
              ],
              // Opção para web e mobile
              ListTile(
                leading: Icon(Icons.link),
                title: Text('Inserir URL da imagem'),
                onTap: () {
                  Navigator.of(context).pop();
                  _showUrlInputDialog();
                },
              ),
              // Opção específica para web
              if (kIsWeb)
                ListTile(
                  leading: Icon(Icons.info_outline),
                  title: Text('Como fazer upload na web'),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showWebUploadInfo();
                  },
                ),
              ListTile(
                leading: Icon(Icons.cancel),
                title: Text('Cancelar'),
                onTap: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showWebUploadInfo() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Upload de Imagem na Web'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Para fazer upload de imagem na versão web:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 12),
              Text('1. Faça upload da imagem em um serviço online:'),
              SizedBox(height: 8),
              Text('• Imgur (imgur.com) - Gratuito'),
              Text('• Google Drive - Compartilhar e copiar link'),
              Text('• Dropbox - Compartilhar e copiar link'),
              SizedBox(height: 12),
              Text('2. Copie o link da imagem'),
              SizedBox(height: 8),
              Text('3. Use a opção "Inserir URL da imagem"'),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Dica: URLs de imagens devem terminar com .jpg, .png, .gif, etc.',
                  style: TextStyle(fontSize: 12, color: Colors.blue.shade700),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showUrlInputDialog();
              },
              child: Text('Inserir URL'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Fechar'),
            ),
          ],
        );
      },
    );
  }

  void _showUrlInputDialog() {
    final TextEditingController urlController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Inserir URL da Imagem'),
          content: TextField(
            controller: urlController,
            decoration: InputDecoration(
              hintText: 'https://exemplo.com/imagem.jpg',
              labelText: 'URL da imagem',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (urlController.text.isNotEmpty) {
                  _setProfileImageFromUrl(urlController.text);
                  Navigator.of(context).pop();
                }
              },
              child: Text('Salvar'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _setProfileImageFromUrl(String imageUrl) async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Atualizar o documento do usuário com a URL da imagem
      await FirebaseFirestore.instance
          .collection('jogadoras')
          .doc(_userId!)
          .update({'profileImageUrl': imageUrl});

      setState(() {
        _profileImageUrl = imageUrl;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil atualizada com sucesso!'),
          backgroundColor: KConstants.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar URL da imagem: $e'),
          backgroundColor: KConstants.errorColor,
        ),
      );
    }
  }

  Future<void> _pickImageFromSource(ImageSource source) async {
    // Se estiver na web, mostrar mensagem explicativa
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Upload de imagem não suportado na versão web. Use a opção "Inserir URL da imagem".',
          ),
          backgroundColor: KConstants.warningColor,
          duration: Duration(seconds: 5),
        ),
      );
      return;
    }

    try {
      if (!mounted) return;

      // Tentar usar o image_picker apenas em mobile
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 80,
      );

      if (image != null && mounted) {
        await _uploadProfileImage(File(image.path));
      }
    } catch (e) {
      if (mounted) {
        // Tratamento de erros específicos para diferentes plataformas
        String errorMessage = 'Erro ao acessar a galeria/câmera';
        if (e.toString().contains('MissingPluginException')) {
          errorMessage =
              'Plugin de imagem não encontrado. Tente reinstalar o app.';
        } else if (e.toString().contains('Permission')) {
          errorMessage = 'Permissão negada. Verifique as configurações do app.';
        } else if (e.toString().contains('unsupported operation')) {
          errorMessage =
              'Operação não suportada nesta plataforma. Use a opção "Inserir URL da imagem".';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: KConstants.errorColor,
            duration: Duration(seconds: 5),
          ),
        );
      }
      print('Erro no image_picker: $e');
    }
  }

  Future<void> _uploadProfileImage(File imageFile) async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Upload da imagem para Firebase Storage
      final ref = FirebaseStorage.instance
          .ref()
          .child('profile_images')
          .child('$_userId.jpg');

      await ref.putFile(imageFile);
      final downloadUrl = await ref.getDownloadURL();

      // Atualizar o documento do usuário
      await FirebaseFirestore.instance
          .collection('jogadoras')
          .doc(_userId!)
          .update({'profileImageUrl': downloadUrl});

      setState(() {
        _profileImageUrl = downloadUrl;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto de perfil atualizada com sucesso!'),
          backgroundColor: KConstants.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao fazer upload da imagem: $e'),
          backgroundColor: KConstants.errorColor,
        ),
      );
    }
  }

  void _showEditProfileDialog() {
    showDialog(
      context: context,
      builder: (context) =>
          _EditProfileDialog(userData: _userData, onSave: _updateUserData),
    );
  }

  Future<void> _updateUserData(Map<String, dynamic> updatedData) async {
    if (_userId == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('jogadoras')
          .doc(_userId!)
          .update(updatedData);

      setState(() {
        _userData = {..._userData!, ...updatedData};
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso!'),
          backgroundColor: KConstants.successColor,
        ),
      );
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao atualizar perfil: $e'),
          backgroundColor: KConstants.errorColor,
        ),
      );
    }
  }

  void _showSettingsDialog() {
    showDialog(
      context: context,
      builder: (context) => _SettingsDialog(
        notificationsEnabled: _notificationsEnabled,
        onNotificationToggle: _saveNotificationSettings,
      ),
    );
  }
}

// Widget para as opções de cadastro
class _RegistrationOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final VoidCallback onTap;

  const _RegistrationOptionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(KConstants.spacingLarge),
        decoration: BoxDecoration(
          color: KConstants.backgroundColor,
          borderRadius: BorderRadius.circular(KConstants.borderRadiusLarge),
          border: Border.all(
            color: KConstants.primaryColor.withOpacity(0.3),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(KConstants.spacingMedium),
              decoration: BoxDecoration(
                color: KConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(
                  KConstants.borderRadiusMedium,
                ),
              ),
              child: Icon(icon, color: KConstants.primaryColor, size: 32),
            ),
            SizedBox(width: KConstants.spacingLarge),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: KTextStyle.titleText),
                  SizedBox(height: KConstants.spacingSmall),
                  Text(
                    description,
                    style: KTextStyle.bodyText.copyWith(
                      color: KConstants.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              color: KConstants.primaryColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para o diálogo de cadastro manual
class _ManualRegistrationDialog extends StatefulWidget {
  final Function(Map<String, dynamic>) onSave;

  const _ManualRegistrationDialog({required this.onSave});

  @override
  State<_ManualRegistrationDialog> createState() =>
      _ManualRegistrationDialogState();
}

class _ManualRegistrationDialogState extends State<_ManualRegistrationDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _cpfController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedPosition;
  bool _isLoading = false;

  final List<String> _positions = [
    'Goleira',
    'Zagueira',
    'Lateral',
    'Volante',
    'Meio-campo',
    'Ponta',
    'Atacante',
    'Centroavante',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _cpfController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KConstants.borderRadiusLarge),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(KConstants.spacingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cadastro Manual',
                    style: KTextStyle.extraLargeTitleText,
                  ),
                  SizedBox(height: KConstants.spacingLarge),

                  // Nome
                  TextFormField(
                    controller: _nameController,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icons.person,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingMedium),

                  // Posição
                  DropdownButtonFormField<String>(
                    value: _selectedPosition,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'Posição',
                      prefixIcon: Icons.sports_soccer,
                    ),
                    items: _positions.map((position) {
                      return DropdownMenuItem(
                        value: position,
                        child: Text(position),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPosition = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Posição é obrigatória';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingMedium),

                  // Telefone
                  TextFormField(
                    controller: _phoneController,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'Telefone',
                      prefixIcon: Icons.phone,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Telefone é obrigatório';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingMedium),

                  // Data de nascimento
                  TextFormField(
                    controller: _birthDateController,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'Data de nascimento',
                      prefixIcon: Icons.calendar_today,
                      hintText: 'DD/MM/AAAA',
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Data de nascimento é obrigatória';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingMedium),

                  // CPF
                  TextFormField(
                    controller: _cpfController,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'CPF',
                      prefixIcon: Icons.badge,
                      hintText: '000.000.000-00',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'CPF é obrigatório';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingMedium),

                  // Endereço
                  TextFormField(
                    controller: _addressController,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'Endereço',
                      prefixIcon: Icons.location_on,
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Endereço é obrigatório';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingExtraLarge),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: Text('Cancelar'),
                        ),
                      ),
                      SizedBox(width: KConstants.spacingMedium),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveData,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final userData = {
      'name': _nameController.text,
      'position': _selectedPosition,
      'phone': _phoneController.text,
      'birthDate': _birthDateController.text,
      'cpf': _cpfController.text,
      'address': _addressController.text,
      'registrationMethod': 'manual',
    };

    await widget.onSave(userData);
    Navigator.pop(context);
  }
}

// Widget para o diálogo de questionário
class _QuizDialog extends StatefulWidget {
  final Function(String) onComplete;

  const _QuizDialog({required this.onComplete});

  @override
  State<_QuizDialog> createState() => _QuizDialogState();
}

class _QuizDialogState extends State<_QuizDialog> {
  int _currentQuestion = 0;
  int _totalQuestions = 0;
  Map<int, String> _answers = {};
  bool _isLoading = false;

  final List<Map<String, dynamic>> _questions = [
    {
      'question': 'Mentalidade e Momento Decisivo? É o ultimo minuto de um jogo empatado. A bola sobra para você
                   no meio-campo. Qual é a sua primeira reação?',
      'options': [
        'Chuto com toda a força',
        'Arranco pela lateral para cruzar',
        'Procuro o melhor passe',
        'Protejo a bola e toco com segurança',
        'Recomponho a defesa',
      ],
      'weights': {
        'Chuto com toda a força': {
          'Goleira': 0,
          'Zagueira': 1,
          'Lateral': 3,
          'Volante': 3,
          'Meio-campo': 3,
          'Ponta': 3,
          'Atacante': 4,
          'Centroavante': 5,
        },
        'Arranco pela lateral para cruzar': {
          'Goleira': 2,
          'Zagueira': 3,
          'Lateral': 5,
          'Volante': 5,
          'Meio-campo': 5,
          'Ponta Esquerda': 5,
          'Atacante': 4,
          'Centroavante': 3,
        },
        'Procuro o melhor passe': {
          'Goleira': 3,
          'Zagueira': 3,
          'Lateral': 5,
          'Volante': 5,
          'Meio-campo': 5,
          'Ponta Direita': 5,
          'Atacante': 2,
          'Centroavante': 1,
        },
        'Protejo a bola e toco com segurança': {
          'Goleira': 5,
          'Zagueira': 5,
          'Lateral Direita': 3,
          'Volante': 3,
          'Meio-campo':3,
          'Ponta Esquerda': 2,
          'Atacante': 1,
          'Centroavante': 1,
        },
        'Recomponho a defesa':{
          'Goleira': 4,
          'Zagueira': 5,
          'Lateral Direita': 4,
          'Volante': 2,
          'Meio-campo':3,
          'Ponta Esquerda': 2,
          'Atacante': 1,
          'Centroavante': 1,
        }
      },
    },
    {
      'question': 'Qual é sua velocidade?',
      'options': ['Muito rápida', 'Rápida', 'Média', 'Lenta'],
      'weights': {
        'Muito rápida': {
          'Goleira': 1,
          'Zagueira': 2,
          'Lateral Direita': 5,
          'Lateral Esquerda': 5,
          'Volante': 4,
          'Meio-campo': 4,
          'Ponta Direita': 5,
          'Ponta Esquerda': 5,
          'Atacante': 5,
          'Centroavante': 3,
        },
        'Rápida': {
          'Goleira': 2,
          'Zagueira': 3,
          'Lateral Direita': 4,
          'Lateral Esquerda': 4,
          'Volante': 4,
          'Meio-campo': 5,
          'Ponta Direita': 4,
          'Ponta Esquerda': 4,
          'Atacante': 4,
          'Centroavante': 3,
        },
        'Média': {
          'Goleira': 4,
          'Zagueira': 4,
          'Lateral Direita': 3,
          'Lateral Esquerda': 3,
          'Volante': 4,
          'Meio-campo': 4,
          'Ponta Direita': 3,
          'Ponta Esquerda': 3,
          'Atacante': 3,
          'Centroavante': 4,
        },
        'Lenta': {
          'Goleira': 5,
          'Zagueira': 5,
          'Lateral Direita': 1,
          'Lateral Esquerda': 1,
          'Volante': 3,
          'Meio-campo': 2,
          'Ponta Direita': 1,
          'Ponta Esquerda': 1,
          'Atacante': 2,
          'Centroavante': 5,
        },
      },
    },
    {
      'question': 'Qual é sua principal qualidade técnica?',
      'options': ['Passe', 'Drible', 'Finalização', 'Defesa'],
      'weights': {
        'Passe': {
          'Goleira': 2,
          'Zagueira': 4,
          'Lateral Direita': 4,
          'Lateral Esquerda': 4,
          'Volante': 5,
          'Meio-campo': 5,
          'Ponta Direita': 4,
          'Ponta Esquerda': 4,
          'Atacante': 3,
          'Centroavante': 3,
        },
        'Drible': {
          'Goleira': 1,
          'Zagueira': 1,
          'Lateral Direita': 3,
          'Lateral Esquerda': 3,
          'Volante': 2,
          'Meio-campo': 3,
          'Ponta Direita': 5,
          'Ponta Esquerda': 5,
          'Atacante': 5,
          'Centroavante': 4,
        },
        'Finalização': {
          'Goleira': 1,
          'Zagueira': 1,
          'Lateral Direita': 2,
          'Lateral Esquerda': 2,
          'Volante': 2,
          'Meio-campo': 3,
          'Ponta Direita': 4,
          'Ponta Esquerda': 4,
          'Atacante': 5,
          'Centroavante': 5,
        },
        'Defesa': {
          'Goleira': 5,
          'Zagueira': 5,
          'Lateral Direita': 4,
          'Lateral Esquerda': 4,
          'Volante': 4,
          'Meio-campo': 2,
          'Ponta Direita': 1,
          'Ponta Esquerda': 1,
          'Atacante': 1,
          'Centroavante': 1,
        },
      },
    },
    {
      'question': 'Onde você se sente mais confortável em campo?',
      'options': ['Defesa', 'Meio-campo', 'Ataque', 'Lados do campo'],
      'weights': {
        'Defesa': {
          'Goleira': 5,
          'Zagueira': 5,
          'Lateral': 3,
          'Volante': 4,
          'Meio-campo': 2,
          'Ponta': 1,
          'Atacante': 1,
          'Centroavante': 1,
        },
        'Meio-campo': {
          'Goleira': 5,
          'Zagueira': 5,
          'Lateral': 3,
          'Volante': 4,
          'Meio-campo': 2,
          'Ponta': 1,
          'Atacante': 1,
          'Centroavante': 1,
        },
        'Ataque': {
          'Goleira': 5,
          'Zagueira': 5,
          'Lateral': 3,
          'Volante': 4,
          'Meio-campo': 2,
          'Ponta': 1,
          'Atacante': 1,
          'Centroavante': 1,
        },
        'Lados do campo': {
          'Goleira': 5,
          'Zagueira': 5,
          'Lateral': 3,
          'Volante': 4,
          'Meio-campo': 2,
          'Ponta': 1,
          'Atacante': 1,
          'Centroavante': 1,
        },
      },
    },
    {
      'question': 'Qual é seu estilo de jogo preferido?',
      'options': ['Ofensivo', 'Defensivo', 'Equilibrado', 'Criativo'],
      'weights': {
        'Ofensivo': {
          'Goleira': 5,
          'Zagueira': 5,
          'Lateral': 3,
          'Volante': 4,
          'Meio-campo': 2,
          'Ponta': 1,
          'Atacante': 1,
          'Centroavante': 1,
        },
        'Defensivo': {
          'Goleira': 5,
          'Zagueira': 5,
          'Lateral': 3,
          'Volante': 4,
          'Meio-campo': 2,
          'Ponta': 1,
          'Atacante': 1,
          'Centroavante': 1,
        },
        'Equilibrado': {
          'Goleira': 5,
          'Zagueira': 5,
          'Lateral': 3,
          'Volante': 4,
          'Meio-campo': 2,
          'Ponta': 1,
          'Atacante': 1,
          'Centroavante': 1,
        },
        'Criativo': {
          'Goleira': 5,
          'Zagueira': 5,
          'Lateral': 3,
          'Volante': 4,
          'Meio-campo': 2,
          'Ponta': 1,
          'Atacante': 1,
          'Centroavante': 1,
        },
      },
    },
  ];

  @override
  void initState() {
    super.initState();
    _totalQuestions = _questions.length;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentQuestion >= _totalQuestions) {
      return _buildResult();
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KConstants.borderRadiusLarge),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: EdgeInsets.all(KConstants.spacingLarge),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progresso
              Row(
                children: [
                  Text('Pergunta ${_currentQuestion + 1} de $_totalQuestions'),
                  Spacer(),
                  Text(
                    '${((_currentQuestion + 1) / _totalQuestions * 100).round()}%',
                  ),
                ],
              ),
              SizedBox(height: KConstants.spacingSmall),
              LinearProgressIndicator(
                value: (_currentQuestion + 1) / _totalQuestions,
                backgroundColor: KConstants.surfaceColor.withOpacity(0.3),
                valueColor: AlwaysStoppedAnimation<Color>(
                  KConstants.primaryColor,
                ),
              ),
              SizedBox(height: KConstants.spacingLarge),

              // Pergunta
              Text(
                _questions[_currentQuestion]['question'],
                style: KTextStyle.titleText,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: KConstants.spacingLarge),

              // Opções
              ...(_questions[_currentQuestion]['options'] as List<String>).map((
                option,
              ) {
                return Padding(
                  padding: EdgeInsets.only(bottom: KConstants.spacingMedium),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => _selectAnswer(option),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KConstants.backgroundColor,
                        foregroundColor: KConstants.primaryColor,
                        side: BorderSide(color: KConstants.primaryColor),
                        padding: EdgeInsets.symmetric(
                          vertical: KConstants.spacingMedium,
                        ),
                      ),
                      child: Text(option),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  void _selectAnswer(String answer) {
    setState(() {
      _answers[_currentQuestion] = answer;
      _currentQuestion++;
    });
  }

  Widget _buildResult() {
    final position = _calculatePosition();

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: EdgeInsets.all(KConstants.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.emoji_events, size: 80, color: KConstants.primaryColor),
            SizedBox(height: KConstants.spacingLarge),
            Text(
              'Sua posição ideal é:',
              style: KTextStyle.titleText,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: KConstants.spacingMedium),
            Text(
              position,
              style: KTextStyle.extraLargeTitleText.copyWith(
                color: KConstants.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: KConstants.spacingLarge),
            Text(
              'Baseado nas suas respostas, esta é a posição que melhor se adequa ao seu perfil!',
              style: KTextStyle.bodyText,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: KConstants.spacingExtraLarge),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Refazer'),
                  ),
                ),
                SizedBox(width: KConstants.spacingMedium),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading
                        ? null
                        : () => _confirmPosition(position),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text('Confirmar'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _calculatePosition() {
    Map<String, int> scores = {};

    for (int i = 0; i < _answers.length; i++) {
      String answer = _answers[i]!;
      Map<String, int> weights = _questions[i]['weights'][answer];

      weights.forEach((position, weight) {
        scores[position] = (scores[position] ?? 0) + weight;
      });
    }

    String bestPosition = scores.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;

    return bestPosition;
  }

  void _confirmPosition(String position) async {
    setState(() {
      _isLoading = true;
    });

    await widget.onComplete(position);
    Navigator.pop(context);
  }
}

// Widget para edição de perfil
class _EditProfileDialog extends StatefulWidget {
  final Map<String, dynamic>? userData;
  final Function(Map<String, dynamic>) onSave;

  const _EditProfileDialog({required this.userData, required this.onSave});

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _birthDateController = TextEditingController();
  final _cpfController = TextEditingController();
  final _addressController = TextEditingController();
  String? _selectedPosition;
  bool _isLoading = false;

  final List<String> _positions = [
    'Goleira',
    'Zagueira',
    'Lateral Direita',
    'Lateral Esquerda',
    'Volante',
    'Meio-campo',
    'Ponta Direita',
    'Ponta Esquerda',
    'Atacante',
    'Centroavante',
  ];

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    if (widget.userData != null) {
      _nameController.text = widget.userData!['name'] ?? '';
      _phoneController.text = widget.userData!['phone'] ?? '';
      _birthDateController.text = widget.userData!['birthDate'] ?? '';
      _cpfController.text = widget.userData!['cpf'] ?? '';
      _addressController.text = widget.userData!['address'] ?? '';
      _selectedPosition = widget.userData!['position'];
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _birthDateController.dispose();
    _cpfController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KConstants.borderRadiusLarge),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(KConstants.spacingLarge),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Editar Perfil', style: KTextStyle.extraLargeTitleText),
                  SizedBox(height: KConstants.spacingLarge),

                  // Nome
                  TextFormField(
                    controller: _nameController,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'Nome completo',
                      prefixIcon: Icons.person,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nome é obrigatório';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingMedium),

                  // Posição
                  DropdownButtonFormField<String>(
                    value: _selectedPosition,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'Posição',
                      prefixIcon: Icons.sports_soccer,
                    ),
                    items: _positions.map((position) {
                      return DropdownMenuItem(
                        value: position,
                        child: Text(position),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedPosition = value;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Posição é obrigatória';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingMedium),

                  // Telefone
                  TextFormField(
                    controller: _phoneController,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'Telefone',
                      prefixIcon: Icons.phone,
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Telefone é obrigatório';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingMedium),

                  // Data de nascimento
                  TextFormField(
                    controller: _birthDateController,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'Data de nascimento',
                      prefixIcon: Icons.calendar_today,
                      hintText: 'DD/MM/AAAA',
                    ),
                    keyboardType: TextInputType.datetime,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Data de nascimento é obrigatória';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingMedium),

                  // CPF
                  TextFormField(
                    controller: _cpfController,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'CPF',
                      prefixIcon: Icons.badge,
                      hintText: '000.000.000-00',
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'CPF é obrigatório';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingMedium),

                  // Endereço
                  TextFormField(
                    controller: _addressController,
                    decoration: KInputDecoration.textFieldDecoration(
                      labelText: 'Endereço',
                      prefixIcon: Icons.location_on,
                    ),
                    maxLines: 2,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Endereço é obrigatório';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: KConstants.spacingExtraLarge),

                  // Botões
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: _isLoading
                              ? null
                              : () => Navigator.pop(context),
                          child: Text('Cancelar'),
                        ),
                      ),
                      SizedBox(width: KConstants.spacingMedium),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveData,
                          child: _isLoading
                              ? SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text('Salvar'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _saveData() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    final updatedData = {
      'name': _nameController.text,
      'position': _selectedPosition,
      'phone': _phoneController.text,
      'birthDate': _birthDateController.text,
      'cpf': _cpfController.text,
      'address': _addressController.text,
    };

    await widget.onSave(updatedData);
    Navigator.pop(context);
  }
}

// Widget para configurações
class _SettingsDialog extends StatelessWidget {
  final bool notificationsEnabled;
  final Function(bool) onNotificationToggle;

  const _SettingsDialog({
    required this.notificationsEnabled,
    required this.onNotificationToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(KConstants.borderRadiusLarge),
      ),
      child: Padding(
        padding: EdgeInsets.all(KConstants.spacingLarge),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Configurações', style: KTextStyle.extraLargeTitleText),
            SizedBox(height: KConstants.spacingLarge),

            // Configuração de notificações
            Container(
              padding: EdgeInsets.all(KConstants.spacingLarge),
              decoration: BoxDecoration(
                color: KConstants.primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications,
                    color: KConstants.primaryColor,
                    size: 24,
                  ),
                  SizedBox(width: KConstants.spacingMedium),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notificações',
                          style: KTextStyle.titleText.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Receber alertas e atualizações',
                          style: KTextStyle.bodyText.copyWith(
                            color: KConstants.textSecondaryColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: notificationsEnabled,
                    onChanged: onNotificationToggle,
                    activeColor: KConstants.primaryColor,
                  ),
                ],
              ),
            ),
            SizedBox(height: KConstants.spacingLarge),

            // Botão de fechar
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
