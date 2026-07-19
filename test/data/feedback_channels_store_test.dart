import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:breathin/data/feedback_channels_store.dart';
import 'package:breathin/domain/models/feedback_channels.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('save/load — раундтрип сохраняет все поля', () async {
    final store = FeedbackChannelsStore();
    const channels = FeedbackChannels(
      voice: true,
      sound: false,
      metronome: true,
      vibration: false,
      visual: true,
    );
    await store.save(channels);
    final loaded = await store.load();
    expect(loaded, channels);
  });

  test('load без данных возвращает дефолт', () async {
    final loaded = await FeedbackChannelsStore().load();
    expect(loaded, const FeedbackChannels());
  });

  test('битый JSON → дефолт, не падает', () async {
    SharedPreferences.setMockInitialValues({'app.feedback': 'не json'});
    final loaded = await FeedbackChannelsStore().load();
    expect(loaded, const FeedbackChannels());
  });
}
