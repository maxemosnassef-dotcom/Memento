import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:cryptography/cryptography.dart';
import 'package:uuid/uuid.dart';

import '../core/security/key_vault.dart';
import '../data/datasources/local/contact_local_data_source.dart';
import '../data/datasources/local/memento_database.dart';
import '../data/datasources/local/memory_local_data_source.dart';
import '../data/repositories/contact_repository_impl.dart';
import '../data/repositories/memory_repository_impl.dart';
import '../data/repositories/secure_alert_throttle.dart';
import '../data/security/aes_gcm_crypto_engine.dart';
import '../data/security/secure_key_vault.dart';
import '../data/services/encrypted_media_ingestor.dart';
import '../data/services/encrypted_media_store.dart';
import '../data/services/geolocator_location_port.dart';
import '../data/services/system_notification_port.dart';
import '../domain/repositories/alert_throttle.dart';
import '../domain/repositories/contact_repository.dart';
import '../domain/repositories/location_port.dart';
import '../domain/repositories/media_ingest_port.dart';
import '../domain/repositories/memory_repository.dart';
import '../domain/repositories/notification_port.dart';
import '../domain/usecases/create_memory.dart';
import '../domain/usecases/find_memories_nearby.dart';
import '../domain/usecases/get_on_this_day_memories.dart';
import '../domain/usecases/get_photo_image.dart';
import '../domain/usecases/load_contacts.dart';
import '../domain/usecases/query_memories_between.dart';
import '../domain/usecases/resolve_current_anchor.dart';
import '../domain/usecases/run_birthday_sweep.dart';
import '../domain/usecases/sync_memory_hotspots.dart';
import '../domain/usecases/upsert_contact.dart';

class AppContainer {
  final SecureKeyVault keyVault;
  final MementoDatabase database;
  final CryptoEngine cryptoEngine;
  final EncryptedMediaStore mediaStore;

  final MemoryRepository memoryRepository;
  final ContactRepository contactRepository;
  final LocationPort locationPort;
  final NotificationPort notificationPort;
  final AlertThrottle alertThrottle;
  final MediaIngestPort mediaIngest;

  final QueryMemoriesBetween memoriesBetween;
  final GetOnThisDayMemories onThisDayMemories;
  final FindMemoriesNearby memoriesNearby;
  final SyncMemoryHotspots hotspotSync;
  final RunBirthdaySweep birthdaySweep;
  final CreateMemory createMemory;
  final LoadContacts loadContacts;
  final UpsertContact upsertContact;
  final GetPhotoImage photoImage;
  final ResolveCurrentAnchor currentAnchor;

  const AppContainer._({
    required this.keyVault,
    required this.database,
    required this.cryptoEngine,
    required this.mediaStore,
    required this.memoryRepository,
    required this.contactRepository,
    required this.locationPort,
    required this.notificationPort,
    required this.alertThrottle,
    required this.mediaIngest,
    required this.memoriesBetween,
    required this.onThisDayMemories,
    required this.memoriesNearby,
    required this.hotspotSync,
    required this.birthdaySweep,
    required this.createMemory,
    required this.loadContacts,
    required this.upsertContact,
    required this.photoImage,
    required this.currentAnchor,
  });
}

Future<AppContainer> buildContainer({
  LocationPort? locationPortOverride,
  NotificationPort? notificationPortOverride,
}) async {
  final keyVault = SecureKeyVault();

  final database = MementoDatabase(keyVault);
  await database.instance;

  final mediaMasterKey = await keyVault.mediaMasterKey();
  final cryptoEngine = AesGcmCryptoEngine(SecretKey(mediaMasterKey));

  const uuid = Uuid();
  final mediaStore = EncryptedMediaStore(cryptoEngine, uuid: uuid);
  final mediaIngest = EncryptedMediaIngestor(mediaStore, uuid: uuid);

  final memoryLocal = MemoryLocalDataSource(database);
  final contactLocal = ContactLocalDataSource(database);

  final memoryRepository = MemoryRepositoryImpl(memoryLocal);
  final contactRepository = ContactRepositoryImpl(contactLocal);

  final locationPort =
      locationPortOverride ?? GeolocatorLocationPort();
  final notificationPort = notificationPortOverride ??
      SystemNotificationPort(FlutterLocalNotificationsPlugin());
  if (notificationPort is SystemNotificationPort) {
    await notificationPort.initialize();
  }

  return AppContainer._(
    keyVault: keyVault,
    database: database,
    cryptoEngine: cryptoEngine,
    mediaStore: mediaStore,
    memoryRepository: memoryRepository,
    contactRepository: contactRepository,
    locationPort: locationPort,
    notificationPort: notificationPort,
    alertThrottle: SecureAlertThrottle(keyVault),
    mediaIngest: mediaIngest,
    memoriesBetween: QueryMemoriesBetween(memoryRepository),
    onThisDayMemories: GetOnThisDayMemories(memoryRepository),
    memoriesNearby: FindMemoriesNearby(memoryRepository, locationPort),
    hotspotSync: SyncMemoryHotspots(memoryRepository, locationPort),
    birthdaySweep: RunBirthdaySweep(
      contactRepository,
      memoryRepository,
      notificationPort,
      SecureAlertThrottle(keyVault),
    ),
    createMemory: CreateMemory(
      memoryRepository,
      mediaIngest,
      idFactory: uuid.v4,
    ),
    loadContacts: LoadContacts(contactRepository),
    upsertContact: UpsertContact(contactRepository, idFactory: uuid.v4),
    photoImage: GetPhotoImage(mediaIngest),
    currentAnchor: ResolveCurrentAnchor(locationPort),
  );
}
