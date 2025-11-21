part of 'loader_cubit.dart';

@immutable
sealed class LoaderState {}

final class LoaderInitial extends LoaderState {}

final class LoaderCompleted extends LoaderState {}
