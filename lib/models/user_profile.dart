import 'package:equatable/equatable.dart';

class UserProfile extends Equatable {
  const UserProfile({
    this.fullName = '',
    this.email = '',
    this.phone = '',
    this.occupation = '',
    this.address = '',
    this.notes = '',
  });

  final String fullName;
  final String email;
  final String phone;
  final String occupation;
  final String address;
  final String notes;

  bool get hasAnyData =>
      fullName.isNotEmpty ||
      email.isNotEmpty ||
      phone.isNotEmpty ||
      occupation.isNotEmpty ||
      address.isNotEmpty;

  String get displayName =>
      fullName.isNotEmpty ? fullName : (email.isNotEmpty ? email : 'Profil');

  UserProfile copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? occupation,
    String? address,
    String? notes,
  }) {
    return UserProfile(
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      occupation: occupation ?? this.occupation,
      address: address ?? this.address,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() => {
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'occupation': occupation,
        'address': address,
        'notes': notes,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      occupation: json['occupation'] as String? ?? '',
      address: json['address'] as String? ?? '',
      notes: json['notes'] as String? ?? '',
    );
  }

  @override
  List<Object?> get props =>
      [fullName, email, phone, occupation, address, notes];
}
