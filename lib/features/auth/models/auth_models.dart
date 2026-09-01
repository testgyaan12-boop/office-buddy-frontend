class LoginRequest {
  final String email;
  final String password;

  LoginRequest({required this.email, required this.password});

  Map<String, dynamic> toJson() => {'email': email, 'password': password};
}

class RegisterRequest {
  final String name;
  final String email;
  final String password;

  RegisterRequest({
    required this.name,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'password': password,
      };
}

class VerifyEmailRequest {
  final String token;
  VerifyEmailRequest({required this.token});
  Map<String, dynamic> toJson() => {'token': token};
}

class ResendVerificationRequest {
  final String email;
  ResendVerificationRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}

class ForgotPasswordRequest {
  final String email;
  ForgotPasswordRequest({required this.email});
  Map<String, dynamic> toJson() => {'email': email};
}

class ResetPasswordRequest {
  final String email;
  final String otp;
  final String newPassword;
  ResetPasswordRequest({
    required this.email,
    required this.otp,
    required this.newPassword,
  });
  Map<String, dynamic> toJson() => {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      };
}

class AuthResponse {
  final String token;
  final String refreshToken;
  final UserModel user;

  AuthResponse({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        token: json['accessToken'] as String,
        refreshToken: json['refreshToken'] as String,
        user: UserModel.fromJson(json['user'] as Map<String, dynamic>),
      );
}

class UserModel {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? headline;
  final String? dateOfBirth;
  final String? gender;
  final String? phone;
  final String? currentCompany;
  final String? salary;
  final String? expectedSalary;
  final String? skills;
  final String? address;
  final String? bloodGroup;
  final String? linkedInUrl;
  final String? portfolioUrl;
  final String? panNumber;
  final String? aadhaarNumber;
  final String? uanNumber;
  final String? pfNumber;
  final String? bankAccountNumber;
  final String? ifscCode;
  final String? emergencyContact;

  UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.headline,
    this.dateOfBirth,
    this.gender,
    this.phone,
    this.currentCompany,
    this.salary,
    this.expectedSalary,
    this.skills,
    this.address,
    this.bloodGroup,
    this.linkedInUrl,
    this.portfolioUrl,
    this.panNumber,
    this.aadhaarNumber,
    this.uanNumber,
    this.pfNumber,
    this.bankAccountNumber,
    this.ifscCode,
    this.emergencyContact,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        avatarUrl: json['avatarUrl'] as String?,
        headline: json['headline'] as String?,
        dateOfBirth: json['dateOfBirth'] as String?,
        gender: json['gender'] as String?,
        phone: json['phone'] as String?,
        currentCompany: json['currentCompany'] as String?,
        salary: json['salary'] as String?,
        expectedSalary: json['expectedSalary'] as String?,
        skills: json['skills'] as String?,
        address: json['address'] as String?,
        bloodGroup: json['bloodGroup'] as String?,
        linkedInUrl: json['linkedInUrl'] as String?,
        portfolioUrl: json['portfolioUrl'] as String?,
        panNumber: json['panNumber'] as String?,
        aadhaarNumber: json['aadhaarNumber'] as String?,
        uanNumber: json['uanNumber'] as String?,
        pfNumber: json['pfNumber'] as String?,
        bankAccountNumber: json['bankAccountNumber'] as String?,
        ifscCode: json['ifscCode'] as String?,
        emergencyContact: json['emergencyContact'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'avatarUrl': avatarUrl,
        'headline': headline,
        'dateOfBirth': dateOfBirth,
        'gender': gender,
        'phone': phone,
        'currentCompany': currentCompany,
        'salary': salary,
        'expectedSalary': expectedSalary,
        'skills': skills,
        'address': address,
        'bloodGroup': bloodGroup,
        'linkedInUrl': linkedInUrl,
        'portfolioUrl': portfolioUrl,
        'panNumber': panNumber,
        'aadhaarNumber': aadhaarNumber,
        'uanNumber': uanNumber,
        'pfNumber': pfNumber,
        'bankAccountNumber': bankAccountNumber,
        'ifscCode': ifscCode,
        'emergencyContact': emergencyContact,
      };
}
