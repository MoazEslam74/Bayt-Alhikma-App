// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'local_storage_services.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class UserProfileAdapter extends TypeAdapter<UserProfile> {
  @override
  final int typeId = 0;

  @override
  UserProfile read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return UserProfile(
      uid: fields[0] as String,
      firstname: fields[1] as String,
      lastname: fields[2] as String,
      username: fields[3] as String,
      email: fields[4] as String,
      categories: (fields[5] as List).cast<String>(),
      favorites: (fields[6] as List?)?.cast<String>(),
      avatar: fields[7] as String?,
      // Read new field
      isSecure: fields[8] as bool?,
    );
  }

  @override
  void write(BinaryWriter writer, UserProfile obj) {
    writer
      ..writeByte(9) // Increased count to 9
      ..writeByte(0)
      ..write(obj.uid)
      ..writeByte(1)
      ..write(obj.firstname)
      ..writeByte(2)
      ..write(obj.lastname)
      ..writeByte(3)
      ..write(obj.username)
      ..writeByte(4)
      ..write(obj.email)
      ..writeByte(5)
      ..write(obj.categories)
      ..writeByte(6)
      ..write(obj.favorites)
      ..writeByte(7)
      ..write(obj.avatar)
      // Write new field
      ..writeByte(8)
      ..write(obj.isSecure);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfileAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
