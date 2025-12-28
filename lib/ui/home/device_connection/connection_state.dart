part of 'connection_cubit.dart';

sealed class ConnectionState {}

final class ConnectionInitial extends ConnectionState {}

final class ConnectionConnecting extends ConnectionState {}

final class ConnectionEstablished extends ConnectionState {}

final class ConnectionPaused extends ConnectionState {}
