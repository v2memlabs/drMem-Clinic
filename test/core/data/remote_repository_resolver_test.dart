import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/data/backend_config.dart';
import 'package:v2mem_clinic/core/data/data_backend.dart';
import 'package:v2mem_clinic/core/data/remote_repository_resolver.dart';

void main() {
  tearDown(() {
    AppBackendConfig.activeBackend = DataBackend.mock;
  });

  test('mock backend returns mock factory result', () {
    AppBackendConfig.activeBackend = DataBackend.mock;
    var mockCalled = false;
    var remoteCalled = false;
    var unavailableCalled = false;

    final result = RemoteRepositoryResolver.resolve<String>(
      remoteReady: true,
      mockFactory: () {
        mockCalled = true;
        return 'mock';
      },
      remoteFactory: () {
        remoteCalled = true;
        return 'remote';
      },
      unavailableFactory: () {
        unavailableCalled = true;
        return 'unavailable';
      },
    );

    expect(result, 'mock');
    expect(mockCalled, isTrue);
    expect(remoteCalled, isFalse);
    expect(unavailableCalled, isFalse);
  });

  test('supabase ready returns remote factory result', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    var mockCalled = false;
    var remoteCalled = false;
    var unavailableCalled = false;

    final result = RemoteRepositoryResolver.resolve<String>(
      remoteReady: true,
      mockFactory: () {
        mockCalled = true;
        return 'mock';
      },
      remoteFactory: () {
        remoteCalled = true;
        return 'remote';
      },
      unavailableFactory: () {
        unavailableCalled = true;
        return 'unavailable';
      },
    );

    expect(result, 'remote');
    expect(mockCalled, isFalse);
    expect(remoteCalled, isTrue);
    expect(unavailableCalled, isFalse);
  });

  test('supabase not ready returns unavailable factory result', () {
    AppBackendConfig.activeBackend = DataBackend.supabase;
    var mockCalled = false;
    var remoteCalled = false;
    var unavailableCalled = false;

    final result = RemoteRepositoryResolver.resolve<String>(
      remoteReady: false,
      mockFactory: () {
        mockCalled = true;
        return 'mock';
      },
      remoteFactory: () {
        remoteCalled = true;
        return 'remote';
      },
      unavailableFactory: () {
        unavailableCalled = true;
        return 'unavailable';
      },
    );

    expect(result, 'unavailable');
    expect(mockCalled, isFalse);
    expect(remoteCalled, isFalse);
    expect(unavailableCalled, isTrue);
  });
}
