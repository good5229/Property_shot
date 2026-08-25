import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Flutter 엔진 전에도 접근 가능한 제품 로딩 페이즈를 표시한다', () {
    final index = File('web/index.html').readAsStringSync();
    final bootstrap = File('web/flutter_bootstrap.js').readAsStringSync();

    expect(index, contains('id="app-loading"'));
    expect(index, contains('name="viewport"'));
    expect(index, contains('role="status"'));
    expect(index, contains('role="progressbar"'));
    expect(index, contains('prefers-reduced-motion'));
    expect(index, isNot(contains('aria-valuenow')));
    expect(bootstrap, contains('{{flutter_js}}'));
    expect(bootstrap, contains('{{flutter_build_config}}'));
    expect(bootstrap, contains('onEntrypointLoaded'));
    expect(bootstrap, contains('flutter-first-frame'));
    expect(index, contains('항해 지도를 펼치는 중'));
    expect(bootstrap, contains('게임 엔진을 준비하는 중'));
    expect(bootstrap, contains('섬과 기록을 불러오는 중'));
    expect(bootstrap, contains('첫 화면을 그리는 중'));
    expect(bootstrap, contains('게임을 불러오지 못했습니다'));
    expect(bootstrap, contains("setAttribute('role', 'alert')"));
    expect(
      index,
      contains('onerror="window.propertyShotBootstrapFailed(event)"'),
    );
  });

  test('첫 프레임 뒤 한 번 제거하고 초기화 실패 때 재시도 가능한 alert를 남긴다', () {
    final bootstrap = File('web/flutter_bootstrap.js')
        .readAsStringSync()
        .replaceFirst('{{flutter_js}}', '')
        .replaceFirst('{{flutter_build_config}}', '');
    final script =
        '''
class Element {
  constructor() {
    this.textContent = '';
    this.hidden = false;
    this.attributes = {};
    this.listeners = {};
    this.removed = 0;
    this.classList = {
      values: new Set(),
      contains: (value) => this.classList.values.has(value),
      add: (value) => this.classList.values.add(value),
    };
  }
  setAttribute(key, value) { this.attributes[key] = value; }
  addEventListener(type, listener) { this.listeners[type] = listener; }
  remove() { this.removed += 1; }
}
const elements = {
  'app-loading': new Element(),
  'app-loading-status': new Element(),
  'app-loading-card': new Element(),
  'app-loading-progress': new Element(),
  'app-loading-retry': new Element(),
};
const handlers = {};
global.document = { getElementById: (id) => elements[id] };
global.window = {
  addEventListener: (type, listener) => { handlers[type] = listener; },
  requestAnimationFrame: (callback) => callback(),
  setTimeout: (callback) => callback(),
  location: { reload: () => {} },
};
global.console = { error: () => {}, log: () => {} };
const source = ${jsonEncode(bootstrap)};

async function successCase() {
  global._flutter = { loader: { load: async ({onEntrypointLoaded}) => {
    await onEntrypointLoaded({ initializeEngine: async () => ({runApp: async () => {}}) });
  } } };
  const pending = eval(source);
  await Promise.resolve();
  if (elements['app-loading'].removed !== 0) throw new Error('removed before first frame');
  handlers['flutter-first-frame']();
  await pending;
  if (elements['app-loading'].removed !== 1) throw new Error('not removed exactly once');
  if (elements['app-loading'].attributes['aria-busy'] !== 'false') throw new Error('busy not cleared');
}

async function failureCase() {
  for (const element of Object.values(elements)) {
    element.hidden = false;
    element.removed = 0;
    element.attributes = {};
    element.classList.values.clear();
  }
  global._flutter = { loader: { load: async () => { throw new Error('offline'); } } };
  await eval(source);
  if (elements['app-loading'].removed !== 0) throw new Error('failure loader removed');
  if (elements['app-loading-card'].attributes.role !== 'alert') throw new Error('missing alert');
  if (elements['app-loading-retry'].hidden !== false) throw new Error('retry hidden');
  if (elements['app-loading-progress'].hidden !== true) throw new Error('progress visible');
}

successCase().then(failureCase).catch((error) => { console.log(error); process.exit(1); });
''';
    final result = Process.runSync('node', ['-e', script]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });

  test('외부 bootstrap 파일 다운로드 실패도 HTML 독립 fallback이 복구한다', () {
    final index = File('web/index.html').readAsStringSync();
    final fallback = RegExp(
      r'<script id="bootstrap-fallback">([\s\S]*?)</script>',
    ).firstMatch(index)!.group(1)!;
    final script =
        '''
class Element {
  constructor() { this.hidden = false; this.attributes = {}; this.textContent = ''; }
  setAttribute(key, value) { this.attributes[key] = value; }
}
const elements = {
  'app-loading': new Element(),
  'app-loading-card': new Element(),
  'app-loading-status': new Element(),
  'app-loading-progress': new Element(),
  'app-loading-retry': new Element(),
};
global.document = { getElementById: (id) => elements[id] };
global.window = { location: { reload: () => {} }, console: { error: () => {} } };
global.console = window.console;
eval(${jsonEncode(fallback)});
window.propertyShotBootstrapFailed(new Error('404'));
if (!window.propertyShotBootstrapHasFailed) process.exit(1);
if (elements['app-loading'].attributes['aria-busy'] !== 'false') process.exit(2);
if (elements['app-loading-card'].attributes.role !== 'alert') process.exit(3);
if (elements['app-loading-progress'].hidden !== true) process.exit(4);
if (elements['app-loading-retry'].hidden !== false) process.exit(5);
''';
    final result = Process.runSync('node', ['-e', script]);
    expect(result.exitCode, 0, reason: '${result.stdout}\n${result.stderr}');
  });
}
