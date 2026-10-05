# -*- coding: utf-8 -*-
# Tour spec: each stop = a file, chunks = (start, end, note_html, [concept keys]).
# Notes are written for a beginner reading Dart/Flutter for the first time.

CONCEPTS = {
    "import": ("import", "다른 파일이나 패키지에 있는 코드를 이 파일에서 쓰겠다는 선언입니다. <code>package:이름/...</code>은 <code>pubspec.yaml</code>에 적은 외부 패키지이고, <code>'app/app.dart'</code>처럼 <code>package:</code> 없이 쓴 경로는 우리 프로젝트 안의 파일입니다. VS Code에서 경로를 Ctrl+클릭하면 그 파일이 열립니다."),
    "async": ("async / await / Future", "시간이 걸리는 일(디스크 읽기, 서버 요청)은 결과가 나중에 옵니다. 그 \"나중에 올 값\"을 담는 상자가 <code>Future</code>입니다. 함수에 <code>async</code>를 붙이면 그 안에서 <code>await</code>를 쓸 수 있고, <code>await</code>는 \"이 Future가 끝날 때까지 여기서 기다렸다가 다음 줄로\"라는 뜻입니다. 기다리는 동안 앱이 멈추지는 않습니다."),
    "widget": ("위젯과 위젯 트리", "Flutter에서 화면에 보이는 모든 것(글자, 버튼, 여백, 화면 전체)은 위젯입니다. 위젯은 다른 위젯을 <code>child</code>(하나)나 <code>children</code>(여러 개)로 품어서 나무 모양을 만듭니다. 코드의 괄호 들여쓰기가 곧 화면의 포함 관계입니다."),
    "const": ("const 와 final", "<code>final</code>은 \"한 번 넣으면 다른 값으로 바꿀 수 없는 변수\"입니다. <code>const</code>는 그보다 강해서 \"앱을 빌드할 때 이미 값이 확정된 것\"입니다. 위젯 앞의 <code>const</code>는 Flutter가 그 위젯을 매번 새로 만들지 않고 재사용하게 해서 조금 더 빠릅니다. 붙여도 되는 곳에 안 붙이면 <code>flutter analyze</code>가 알려줍니다."),
    "class": ("class / extends", "<code>class</code>는 설계도입니다. <code>class A extends B</code>는 \"B의 기능을 물려받은 A\"라는 뜻입니다. <code>RoutineApp extends StatelessWidget</code>이면 RoutineApp은 위젯으로서 필요한 기능을 전부 물려받고, 자기만의 <code>build</code>만 새로 쓰면 됩니다."),
    "constructor": ("생성자와 { } 이름 있는 인자", "클래스 이름과 같은 함수(<code>RoutineApp(...)</code>)가 생성자입니다. 객체를 만들 때 불립니다. 괄호 안을 <code>{ }</code>로 감싸면 \"이름 있는 인자\"가 되어 부를 때 <code>ApiClient(baseUrl: '...')</code>처럼 이름을 붙여 넘깁니다. <code>required</code>가 붙으면 꼭 넘겨야 하고, 없으면 생략할 수 있습니다. <code>this.x</code>는 \"받은 값을 바로 내 필드 x에 넣어라\"라는 줄임말입니다."),
    "override": ("@override", "부모 클래스(또는 구현하기로 한 인터페이스)에 이미 있는 함수를 \"내 방식으로 다시 쓴다\"는 표시입니다. 빠뜨려도 동작은 하지만, 이름을 잘못 쓰면 분석기가 잡아주므로 붙이는 게 관례입니다."),
    "build": ("build(context)", "Flutter가 이 위젯을 화면에 그려야 할 때마다 부르는 함수입니다. 여기서 반환한 위젯 트리가 그대로 화면이 됩니다. <code>context</code>는 \"트리 안에서 내 위치\"라서, 테마를 찾거나 <code>context.go()</code>로 화면을 옮길 때 씁니다."),
    "stateful": ("StatefulWidget 과 State", "스스로 바뀌는 값(타이머, 입력 중인 글자, 로딩 중 여부)이 있는 화면은 두 클래스로 나뉩니다. 바깥 <code>StatefulWidget</code>은 껍데기이고, 실제 값과 <code>build</code>는 <code>State</code> 클래스에 있습니다. <code>setState(() { ... })</code>로 값을 바꾸면 Flutter가 <code>build</code>를 다시 불러 화면을 새로 그립니다. <code>initState</code>는 화면이 처음 생길 때 한 번, <code>dispose</code>는 화면이 사라질 때 한 번 불립니다."),
    "private": ("밑줄 _ 로 시작하는 이름", "Dart에서 이름이 <code>_</code>로 시작하면 그 파일 밖에서는 볼 수 없습니다(private). <code>_SplashScreenState</code>, <code>_submit</code>, <code>_box</code>가 그 예입니다. \"이 파일 안에서만 쓰는 내부 부품\"이라는 표시로 읽으면 됩니다."),
    "null": ("? ! ?. ?? (null 관련 기호)", "<code>String?</code>은 \"문자열이거나 null(값 없음)\"입니다. <code>?</code> 없는 타입에는 null이 못 들어갑니다. <code>a?.b</code>는 \"a가 null이면 멈추고 null, 아니면 b\", <code>a ?? b</code>는 \"a가 null이면 b를 대신 써라\", <code>a!</code>는 \"a는 절대 null이 아니라고 내가 보증한다\"입니다(틀리면 앱이 죽습니다)."),
    "arrow": ("=> 화살표 함수", "<code>(x) => 식</code>은 <code>(x) { return 식; }</code>의 줄임말입니다. 한 줄로 끝나는 함수에 씁니다."),
    "provider": ("Riverpod Provider", "앱 여러 곳에서 같이 쓰는 객체를 만들어 두는 \"공용 보관함\"입니다. <code>final xProvider = Provider((ref) => 객체)</code>로 만드는 법을 적어두면, 처음 필요할 때 한 번 만들어서 계속 같은 것을 돌려줍니다. 화면에서는 <code>ref.read(xProvider)</code>(지금 한 번 꺼내기) 또는 <code>ref.watch(xProvider)</code>(꺼내고, 바뀌면 다시 그리기)로 꺼냅니다."),
    "generic": ("< > 제네릭", "<code>List&lt;String&gt;</code>은 \"문자열이 담긴 리스트\", <code>Future&lt;AuthUser&gt;</code>는 \"나중에 AuthUser가 나오는 상자\"처럼, 꺾쇠 안에 \"무엇을 담는지\"를 적는 문법입니다. <code>Map&lt;String, dynamic&gt;</code>은 \"키는 문자열, 값은 아무 타입\"인 사전입니다(서버 JSON이 이 모양으로 들어옵니다)."),
    "abstract": ("abstract class / implements", "<code>abstract class</code>는 \"이런 함수들이 있어야 한다\"는 목록(약속)만 있고 내용은 없는 클래스입니다. <code>class B implements A</code>는 \"B가 A의 약속을 전부 실제로 구현한다\"는 뜻입니다. 화면은 약속(A)만 알고, 실제로 Hive를 쓸지 서버를 쓸지는 B가 정합니다. 그래서 나중에 B만 바꿔 끼우면 화면 코드는 그대로 둘 수 있습니다."),
    "trycatch": ("try / on ... catch / finally", "<code>try { }</code> 안에서 문제가 생겨 예외(Exception)가 던져지면, 그 아래 줄은 건너뛰고 해당 종류를 받는 <code>on 타입 catch (e) { }</code>로 점프합니다. <code>finally { }</code>는 성공하든 실패하든 마지막에 항상 실행됩니다."),
    "getter": ("get (게터)", "<code>Future&lt;Box&lt;Map&gt;&gt; get _box =&gt; ...</code>처럼 <code>get</code>으로 만든 것은 괄호 없이 변수처럼 읽지만, 읽을 때마다 오른쪽 식이 실행되는 함수입니다."),
    "factory": ("factory 생성자 / fromJson", "<code>factory</code>는 \"객체를 만드는 방법을 직접 코드로 정하는 생성자\"입니다. <code>AuthUser.fromJson(json)</code>은 서버에서 온 JSON 사전을 받아 필드를 하나씩 꺼내 AuthUser 객체를 만들어 돌려줍니다. 앱 안에서는 사전 대신 이 객체를 쓰니 오타를 컴파일러가 잡아줍니다."),
}

CHAPTERS = {
    1: "앱이 켜져서 로그인이 끝날 때까지",
    2: "처음 로그인한 보호자의 온보딩",
    3: "홈 화면과 하단 탭, 기기",
    4: "루틴 만들기와 보기",
    5: "프로필과 계정",
}

STOPS = []

STOPS.append(dict(
    file="lib/main.dart",
    title="모든 것이 시작되는 곳",
    role="앱 시작점",
    arrive="앱 아이콘을 누르면 Flutter는 이 파일의 <code>main()</code> 함수를 가장 먼저 실행합니다. 모든 Dart 프로그램의 입구입니다.",
    chunks=[
        (1, 4, "외부 패키지 세 개를 가져옵니다. <code>material</code>은 Flutter 기본 위젯(버튼, 화면 틀 등), <code>flutter_riverpod</code>는 아래 11줄의 <code>ProviderScope</code>, <code>hive_flutter</code>는 9줄의 <code>Hive</code> 때문에 필요합니다. 이 파일에서 실제로 쓰는 이름이 있어야 import가 의미 있습니다.", ["import"]),
        (5, 6, "우리 프로젝트 안의 <code>lib/app/app.dart</code>를 가져옵니다. 11줄의 <code>RoutineApp</code>이 그 파일에 정의돼 있습니다.", []),
        (7, 7, "프로그램 시작 함수입니다. <code>void</code>는 \"돌려주는 값이 없다\", <code>async</code>는 \"이 안에서 <code>await</code>로 기다리는 일이 있다\"는 표시입니다.", ["async"]),
        (8, 8, "Flutter 엔진과 우리 Dart 코드를 먼저 연결합니다. <code>runApp</code> 전에 기기 기능(여기서는 Hive가 쓰는 저장 폴더)을 건드리려면 이 줄이 먼저 있어야 한다는 관례입니다. 줄 끝 <code>;</code>은 \"문장 끝\" 표시입니다.", []),
        (9, 10, "로컬 데이터베이스 Hive를 준비시킵니다. 기기 안 저장 폴더 위치를 찾는 디스크 작업이라 시간이 걸리므로 <code>await</code>로 끝날 때까지 기다립니다. 이 줄이 끝난 뒤부터 앱 어디서든 <code>Hive.openBox(...)</code>로 저장소를 열 수 있습니다.", []),
        (11, 11, "화면 그리기를 시작합니다. 안쪽부터 읽으면 쉽습니다. <code>RoutineApp()</code>은 앱 전체를 뜻하는 위젯이고, 그것을 <code>ProviderScope</code>로 감쌉니다. 감싸야 앱 어디서나 Riverpod provider를 꺼내 쓸 수 있습니다. <code>const</code>는 바뀌지 않는 값이라 재사용하라는 표시입니다.", ["widget", "const"]),
        (12, 12, "<code>main</code> 함수 끝. 이후의 모든 일은 <code>RoutineApp</code> 안에서 일어납니다.", []),
    ],
    next_hint="11줄의 <code>RoutineApp</code>을 Ctrl+클릭하면 다음 파일로 갑니다.",
))

STOPS.append(dict(
    file="lib/app/app.dart",
    title="앱의 뼈대: 테마와 경로표를 끼운다",
    role="MaterialApp 설정",
    arrive="<code>main.dart</code> 11줄 <code>RoutineApp()</code>에서 왔습니다.",
    chunks=[
        (1, 2, "Flutter 기본 위젯 패키지.", []),
        (3, 5, "같은 폴더의 <code>router.dart</code>(경로표 <code>appRouter</code>)와 <code>theme.dart</code>(디자인 기본값 <code>appTheme</code>)를 가져옵니다.", []),
        (6, 6, "<code>RoutineApp</code>이라는 위젯 설계도를 정의합니다. <code>StatelessWidget</code>을 물려받았으니 \"스스로 바뀌는 값이 없는 위젯\"입니다.", ["class"]),
        (7, 8, "생성자입니다. <code>{super.key}</code>는 \"key라는 선택 인자를 받아 부모에게 그대로 넘긴다\"는 뜻인데, 거의 모든 위젯에 붙는 관용구라 외우지 않아도 됩니다.", ["constructor"]),
        (9, 10, "<code>build</code>는 Flutter가 \"이 위젯을 그려야 할 때\" 부르는 함수입니다. 여기서 돌려준 위젯이 화면이 됩니다. <code>@override</code>는 부모(<code>StatelessWidget</code>)에게 원래 있던 <code>build</code>를 내 것으로 바꿔 쓴다는 표시입니다.", ["override", "build"]),
        (11, 11, "앱 전체의 뼈대 위젯 <code>MaterialApp</code>을 만듭니다. 이름 뒤 <code>.router</code>는 \"화면 이동은 go_router 라이브러리에 맡기겠다\"는 버전입니다.", []),
        (12, 12, "앱 이름('TOMO'). 안드로이드 최근 앱 목록 같은 곳에 쓰입니다.", []),
        (13, 13, "모든 화면의 기본 글자 크기·버튼 크기를 <code>theme.dart</code>의 <code>appTheme</code>로 정합니다.", []),
        (14, 14, "\"어떤 주소에 어떤 화면\"인지 적힌 경로표를 넘깁니다. 첫 화면도 여기서 정해집니다. <b>앱 흐름을 따라가려면 여기서 <code>appRouter</code>로 가면 됩니다.</b>", []),
        (15, 17, "괄호 닫기. <code>);</code>는 <code>MaterialApp.router(</code> 호출의 끝, 첫 <code>}</code>는 <code>build</code> 함수 끝, 마지막 <code>}</code>는 클래스 끝입니다. 여는 괄호를 클릭하면 VS Code가 짝 괄호를 강조해 줍니다.", []),
    ],
    next_hint="13줄 <code>appTheme</code>을 먼저 잠깐 보고, 그다음 14줄 <code>appRouter</code>로 갑니다.",
))

STOPS.append(dict(
    file="lib/app/theme.dart",
    title="큰 글씨, 큰 버튼",
    role="디자인 기본값",
    arrive="<code>app.dart</code> 13줄 <code>theme: appTheme</code>에서 잠깐 들렀습니다. 짧은 파일입니다. (feature 브랜치 기준 코드)",
    chunks=[
        (1, 2, "Flutter 기본 위젯 패키지.", []),
        (3, 3, "<code>appTheme</code>이라는 변수를 만들고 <code>ThemeData</code> 객체를 넣습니다. <code>final</code>이라 다른 값으로 바꿀 수 없습니다. 클래스 밖(파일 최상위)에 있어서 이 파일을 import한 곳 어디서나 쓸 수 있습니다.", ["const"]),
        (4, 4, "구글 Material Design 3 스타일을 씁니다. <code>이름: 값</code> 모양은 이름 있는 인자입니다.", []),
        (5, 5, "청록색(teal) 하나를 씨앗으로 앱 전체 색 조합을 자동으로 만듭니다. 다만 실제 화면들은 Figma 색(<code>0xFF4ABEFF</code> 하늘색 등)을 직접 지정하는 경우가 많아 이 색은 잘 드러나지 않습니다.", []),
        (6, 6, "위젯 사이 간격을 기본보다 조금 넉넉하게.", []),
        (7, 11, "기본 글자 크기. Flutter 기본은 14인데 본문을 20/18, 큰 제목을 28로 키웠습니다. 사용자가 보기 쉽게 하려는 의도입니다.", []),
        (12, 17, "<code>ElevatedButton</code>(색이 칠해진 버튼)의 기본값. <code>minimumSize: Size.zero</code>는 \"최소 크기 제한 없음\"입니다. 원래는 <code>Size(88, 56)</code>(누르기 쉬운 큰 버튼)였는데 10월 5일 커밋 <code>dcc641c</code>에서 없앴습니다. 이제 각 버튼이 화면마다 직접 크기를 정합니다. <code>Size.zero</code> 앞에 <code>const</code>가 없는 이유는 <code>Size.zero</code>가 이미 상수라서입니다.", []),
        (18, 18, "<code>ThemeData(</code> 호출 끝.", []),
    ],
    next_hint="<code>app.dart</code>로 돌아가 14줄 <code>appRouter</code>를 Ctrl+클릭합니다.",
))

STOPS.append(dict(
    file="lib/app/router.dart",
    title="주소 → 화면 경로표",
    role="화면 경로표",
    arrive="<code>app.dart</code> 14줄 <code>routerConfig: appRouter</code>에서 왔습니다.",
    chunks=[
        (1, 34, "화면 파일 29개를 전부 import합니다. 경로표가 모든 화면을 알아야 하기 때문입니다. 새 화면을 만들면 여기에 import 한 줄과 아래 <code>GoRoute</code> 하나를 추가합니다. <code>../</code>는 \"한 폴더 위로\"라는 뜻입니다.", ["import"]),
        (35, 39, "이 파일이 무엇인지 설명하는 주석입니다.", []),
        (40, 40, "경로표 객체 <code>appRouter</code>를 만듭니다. 이 괄호는 맨 아래 236줄에서 닫힙니다.", []),
        (41, 43, "<b>앱을 켜면 가장 먼저 <code>/splash</code> 주소로 갑니다.</b> 다음 정류장이 여기서 정해집니다.", []),
        (44, 44, "<code>routes:</code> 뒤 <code>[ ]</code> 안에 경로를 하나씩 나열합니다. <code>[ ]</code>는 리스트(목록)입니다.", []),
        (45, 47, "<code>GoRoute</code> 하나 = \"이 주소면 이 화면\" 한 쌍입니다. <code>builder: (context, state) =&gt; const SplashScreen()</code>은 \"이 주소로 오면 SplashScreen 위젯을 만들어라\"라는 함수입니다.", ["arrow"]),
        (48, 54, "<code>/login</code> 주소면 <code>LoginScreen</code>을 보여줍니다. 위 주석이 로그인 뒤 어디로 가는지 미리 알려줍니다.", []),
        (55, 69, "<code>routes:</code> 안에 또 <code>GoRoute</code>를 넣으면 하위 경로입니다. <code>'social'</code>은 부모 <code>/login</code> 뒤에 붙어 <code>/login/social</code>이 됩니다. 하위 화면에서 뒤로 가면 부모 화면으로 돌아옵니다.", []),
        (70, 84, "온보딩(최초 설정) 3단계 화면 경로. 모양은 위와 같습니다.", []),
        (85, 91, "<code>/</code>(맨 앞 주소)는 홈 화면입니다. 하단 탭 4개 중 첫 번째입니다.", []),
        (92, 165, "루틴 탭과 그 하위 화면들(오늘 할 일, 상세, 추가, 템플릿). <code>'detail/:id'</code>처럼 <code>:</code>가 붙은 부분은 변수입니다. 상세 화면은 주소의 id 대신 목록에서 이미 받은 루틴을 <code>state.extra</code>로 넘겨받습니다. 지금은 훑어만 보고 나중에 루틴 장에서 자세히 읽습니다.", []),
        (166, 205, "기기 탭과 하위 화면들. <code>':name'</code> 변수로 어느 기기인지 받습니다.", []),
        (206, 226, "내 정보 탭과 하위 화면들.", []),
        (227, 244, "탭에 속하지 않는 화면들. <code>/watch-connection</code>은 등록만 돼 있고 이동하는 버튼이 아직 없습니다.", []),
        (245, 246, "<code>routes</code> 리스트 끝(<code>],</code>)과 <code>GoRouter(</code> 호출 끝(<code>);</code>).", []),
    ],
    next_hint="41줄의 첫 주소 <code>/splash</code> → 44줄 <code>SplashScreen</code>을 Ctrl+클릭합니다.",
))

STOPS.append(dict(
    file="lib/features/splash/presentation/splash_screen.dart",
    title="1.5초 로고, 그리고 로그인으로",
    role="스플래시",
    arrive="<code>router.dart</code> 41줄 <code>initialLocation: '/splash'</code> → 43줄 <code>SplashScreen()</code>에서 왔습니다.",
    chunks=[
        (1, 2, "<code>dart:async</code>는 Dart 기본 라이브러리로, 21줄의 <code>Timer</code> 때문에 필요합니다.", []),
        (3, 6, "Flutter 위젯, SVG 그림 표시(<code>SvgPicture</code>), 화면 이동(<code>context.go</code>) 패키지.", []),
        (7, 7, "이 화면이 Figma의 어느 프레임을 옮긴 것인지 적어둔 주석입니다. 이 프로젝트의 모든 화면 파일에 이런 줄이 있습니다.", []),
        (8, 13, "1.5초 뒤 화면을 바꾸는 타이머라는 \"바뀌는 값\"이 있어서 <code>StatefulWidget</code>입니다. 이 바깥 클래스는 껍데기이고, <code>createState()</code>가 실제 내용을 가진 <code>_SplashScreenState</code>를 만듭니다.", ["stateful"]),
        (15, 16, "실제 내용 클래스. 이름이 <code>_</code>로 시작해 이 파일 안에서만 보입니다. <code>Timer? _navigationTimer</code>는 타이머를 담을 변수이고, <code>?</code>는 \"아직 null(비어 있음)일 수 있음\"입니다.", ["private", "null"]),
        (18, 20, "<code>initState</code>는 화면이 처음 만들어질 때 딱 한 번 불립니다. <code>super.initState()</code>로 부모 쪽 준비를 먼저 하는 것은 관례입니다.", []),
        (21, 23, "<b>1500밀리초(1.5초) 뒤에 실행할 함수</b>를 예약합니다. 시간이 되면 <code>context.go('/login')</code>로 로그인 화면으로 갑니다. <code>if (mounted)</code>는 \"그 사이 화면이 이미 사라지지 않았다면\"이라는 안전장치입니다. 사라진 화면의 context를 쓰면 오류가 납니다.", []),
        (24, 24, "<code>initState</code> 끝.", []),
        (26, 30, "<code>dispose</code>는 화면이 사라질 때 한 번 불립니다. 1.5초가 되기 전에 화면이 사라지면 타이머를 취소(<code>cancel</code>)해 둡니다. <code>?.</code>는 \"null이 아니면 cancel 호출\"입니다.", []),
        (32, 33, "화면 모양을 정하는 <code>build</code>.", ["build"]),
        (34, 35, "<code>Scaffold</code>는 \"화면 한 장\"의 기본 틀입니다(배경, 본문, 하단바 자리). 배경은 흰색.", ["widget"]),
        (36, 42, "본문: <code>Center</code>(가운데 정렬) 안에 <code>SizedBox</code>(202×224 크기 상자) 안에 로고 SVG. 바깥에서 안쪽으로 감싸는 구조가 들여쓰기로 보입니다. 숫자는 Figma에서 잰 크기입니다.", []),
        (43, 45, "괄호 닫기: <code>Scaffold(</code> 끝, <code>build</code> 끝, 클래스 끝.", []),
    ],
    next_hint="22줄 <code>context.go('/login')</code> → router.dart의 <code>/login</code> → <code>LoginScreen</code>으로 갑니다.",
))

STOPS.append(dict(
    file="lib/features/auth/presentation/login_screen.dart",
    title="로그인 화면과 _submit()",
    role="로그인 화면",
    arrive="<code>splash_screen.dart</code> 22줄 <code>context.go('/login')</code> → <code>router.dart</code> 52줄 <code>LoginScreen()</code>에서 왔습니다.",
    chunks=[
        (1, 5, "Flutter 위젯, Riverpod(provider 꺼내기), SVG, 화면 이동 패키지.", []),
        (6, 8, "우리 코드 두 개. <code>api_exception.dart</code>는 56줄에서 서버 오류를 잡을 때, <code>auth_providers.dart</code>는 46줄에서 로그인 기능을 꺼낼 때 씁니다.", []),
        (10, 15, "문서 주석. 이 화면의 역할을 요약합니다. 로그인 성공 후 응답에 든 이름(<code>user.name</code>) 유무로 갈 곳을 정한다는 내용입니다.", []),
        (16, 21, "입력 중인 글자, 로딩 중 여부처럼 바뀌는 값이 있어서 Stateful입니다. 스플래시와 다른 점은 <code>Consumer</code>가 붙었다는 것입니다. <code>ConsumerStatefulWidget</code>을 쓰면 State 안에서 <code>ref</code>로 Riverpod provider를 꺼낼 수 있습니다.", ["stateful"]),
        (23, 24, "실제 내용 클래스. <code>static const _brandBlue</code>는 이 클래스 전체가 공유하는 고정 색(Figma 하늘색)입니다. <code>0xFF4ABEFF</code>에서 <code>FF</code>는 불투명도, <code>4ABEFF</code>는 색입니다.", []),
        (26, 26, "<code>_formKey</code>는 입력 폼 전체를 가리키는 손잡이입니다. 39줄에서 \"폼 안의 칸들을 검사해라\"라고 명령할 때 씁니다.", ["generic"]),
        (27, 28, "이메일·비밀번호 입력 칸의 글자를 담는 컨트롤러. 47·48줄에서 <code>.text</code>로 입력값을 꺼냅니다.", []),
        (29, 29, "로그인 요청 중인지 기록하는 값. <code>true</code>면 버튼이 빙글빙글 로딩으로 바뀝니다(123줄).", []),
        (31, 36, "화면이 사라질 때 컨트롤러 두 개를 정리합니다. 정리하지 않으면 메모리가 새는 것이 Flutter 규칙입니다.", []),
        (38, 38, "<b>로그인 버튼을 누르면 실행되는 함수</b>(115줄에서 연결). 서버를 기다리므로 <code>async</code>이고, 돌려주는 값이 없어 <code>Future&lt;void&gt;</code>입니다.", ["async"]),
        (39, 39, "폼 안의 칸들에게 검사를 시킵니다(94·108줄의 <code>validator</code>). 하나라도 비어 있으면 <code>false</code>라서 <code>return</code>으로 함수를 바로 끝냅니다. <code>!</code>는 \"<code>currentState</code>는 null이 아니다\"라는 보증, 앞의 <code>!</code>(<code>!_formKey</code>)는 \"아니면\"(논리 부정)입니다. 같은 기호가 두 가지 뜻으로 쓰입니다.", ["null"]),
        (40, 40, "<code>_submitting</code>을 <code>true</code>로 바꾸고 <code>setState</code>로 화면을 다시 그리게 합니다. 버튼이 로딩 표시로 바뀝니다.", []),
        (41, 41, "여기서부터 실패할 수 있는 일을 시작합니다.", ["trycatch"]),
        (42, 45, "주석. 서버가 로그인 응답에 <code>user</code>(이름 포함)를 담아 주므로, 내 정보(<code>GET /users/me</code>)를 한 번 더 부를 필요가 없다는 설명입니다.", []),
        (46, 49, "<b>다음 정류장으로 가는 줄.</b> <code>ref.read(authRepositoryProvider)</code>로 로그인 담당 객체를 꺼내 <code>.login(email:, password:)</code>을 부르고, 서버 응답이 올 때까지 <code>await</code>로 기다립니다. 결과(<code>AuthUser</code>)를 <code>user</code>에 담습니다. 이 한 줄 뒤에서 무슨 일이 일어나는지 다음 정류장부터 따라갑니다.", ["provider"]),
        (50, 53, "<b>이전 계정의 자녀 정보 버리기.</b> 같은 기기에서 다른 계정으로 로그인할 수도 있어서, 캐시에 남은 자녀 목록(<code>childListProvider</code>)과 \"선택한 자녀\"(<code>selectedChildIdProvider</code>)를 <code>ref.invalidate</code>로 버립니다. 그러면 루틴 탭이 이 계정의 자녀를 서버에서 새로 받아옵니다.", ["invalidate"]),
        (54, 54, "서버를 기다리는 사이 사용자가 화면을 떠났을 수 있으므로 확인합니다. 스플래시의 <code>mounted</code>와 같은 안전장치입니다.", []),
        (55, 55, "<b>이 앱에서 가장 중요한 분기.</b> <code>조건 ? A : B</code>는 \"조건이 참이면 A, 아니면 B\"입니다. 이름이 비어 있으면(첫 로그인) 온보딩으로, 있으면 홈(<code>/</code>)으로 갑니다.", []),
        (56, 58, "46~49줄 어디서든 <code>ApiException</code>이 던져지면 여기로 점프합니다. 서버가 준 한국어 메시지(<code>e.message</code>)를 화면 아래 스낵바(잠깐 떴다 사라지는 알림)로 보여줍니다.", []),
        (59, 62, "성공이든 실패든 마지막에 로딩 표시를 끕니다. 성공해서 다른 화면으로 갔다면 <code>mounted</code>가 false라 건너뜁니다.", []),
        (64, 68, "여기부터 화면 모양입니다. <code>Scaffold</code>(화면 틀) → <code>SafeArea</code>(노치·상태바를 피해 안쪽에 그리기).", ["build"]),
        (69, 72, "<code>Form</code>이 입력 칸들을 묶고, 26줄의 <code>_formKey</code>를 달아둡니다. <code>Column</code>은 자식들을 위에서 아래로 쌓습니다.", []),
        (73, 79, "<code>Spacer(flex: 3)</code>와 <code>Spacer(flex: 2)</code>는 남는 세로 공간을 3:2로 나눠 차지하는 빈칸입니다. 그 사이에 로고(140×155)가 들어갑니다. 화면 크기가 달라도 비율이 유지됩니다.", []),
        (80, 83, "좌우 32 여백 안에 입력 칸들을 또 세로로 쌓습니다.", []),
        (84, 96, "이메일 입력 칸. 27줄의 컨트롤러를 연결하고, 키보드를 이메일용으로, 테두리를 둥글게(반지름 19). <code>validator</code>는 39줄에서 검사할 때 불리는 함수로, 비어 있으면 오류 문구를, 괜찮으면 <code>null</code>을 돌려줍니다.", ["arrow"]),
        (97, 97, "칸 사이 16 높이의 빈 상자. Flutter에서 간격은 이렇게 빈 <code>SizedBox</code>로 만듭니다.", []),
        (98, 110, "비밀번호 칸. <code>obscureText: true</code>로 글자를 ●로 가립니다. 나머지는 이메일 칸과 같습니다.", []),
        (111, 115, "<b>로그인 버튼.</b> <code>width: double.infinity</code>로 가로를 꽉 채웁니다. <code>onPressed: _submitting ? null : _submit</code>은 \"요청 중이면 null(누를 수 없음), 아니면 누를 때 38줄 <code>_submit</code> 실행\"입니다.", []),
        (116, 122, "버튼 색(하늘색 배경, 흰 글자)과 둥근 모서리.", []),
        (123, 134, "버튼 안에 보일 것. 요청 중이면 작은 로딩 원, 아니면 \"로그인\" 글자.", []),
        (135, 138, "괄호 닫기와 16 간격.", []),
        (139, 163, "<code>Row</code>(가로로 나란히) 안에 \"회원가입\", \"아이디/비밀번호 찾기\" 글자 버튼. <code>onPressed: () {}</code>는 아무것도 안 하는 빈 함수라 지금은 눌러도 반응이 없습니다.", []),
        (164, 171, "아래쪽 빈칸(flex 1)과 괄호 닫기들.", []),
    ],
    next_hint="46줄 <code>authRepositoryProvider</code>를 Ctrl+클릭합니다.",
))

STOPS.append(dict(
    file="lib/features/auth/data/auth_providers.dart",
    title="부품 조립 공장",
    role="provider 목록",
    arrive="<code>login_screen.dart</code> 45줄 <code>ref.read(authRepositoryProvider)</code>에서 왔습니다.",
    chunks=[
        (1, 9, "Riverpod과, 조립에 쓸 부품 클래스들을 import합니다.", []),
        (10, 11, "<code>LocalStorageService</code>(Hive 상자를 여는 도구)를 만드는 provider. 이름이 <code>_</code>로 시작해 이 파일 전용입니다.", ["provider", "private"]),
        (12, 15, "로그인 토큰(accessUuid)을 기기에 저장·조회하는 <code>LocalAuthSessionRepository</code>를 만듭니다. 만들 때 위의 저장 도구가 필요해서 <code>ref.watch(...)</code>로 받아 넘깁니다. 이렇게 provider끼리 서로 꺼내 쓰며 부품을 조립합니다.", ["generic"]),
        (16, 19, "주석: 앱 전체가 공유하는 서버 통신 객체를 여기서 만든다는 설명.", []),
        (20, 24, "서버 통신 객체 <code>ApiClient</code>를 만듭니다. <code>getAccessUuid: session.getAccessUuid</code>는 함수를 호출하지 않고 함수 자체를 넘기는 것입니다(괄호 <code>()</code>가 없습니다). 그래서 ApiClient는 요청을 보낼 때마다 이 함수를 불러 최신 토큰을 얻을 수 있습니다.", []),
        (25, 28, "<b>login_screen이 꺼낸 바로 그것.</b> <code>ApiAuthRepository</code>를 만들고, 서버 통신 객체와 세션 저장소를 넘겨줍니다. 타입은 <code>AuthRepository</code>(약속)로 공개해서, 화면은 안쪽이 무엇인지 몰라도 됩니다.", ["abstract"]),
        (29, 32, "<code>userRepositoryProvider</code>도 여기서 만들어집니다. 내 정보 조회·수정 담당입니다.", []),
        (33, 40, "<code>FutureProvider</code>는 \"비동기로 한 번 불러와 기억해 두는\" provider입니다. 내 정보 탭 같은 화면이 <code>ref.watch(currentUserProvider)</code>로 씁니다. 로그인 화면은 이것을 쓰지 않습니다. <code>login()</code>이 돌려준 <code>user</code>로 충분하기 때문입니다.", []),
    ],
    next_hint="조립 순서대로 아래쪽 부품부터 봅니다. 10줄 <code>LocalStorageService</code>를 Ctrl+클릭합니다.",
))

STOPS.append(dict(
    file="lib/core/storage/local_storage_service.dart",
    title="Hive 상자 여는 도구",
    role="Hive 래퍼",
    arrive="<code>auth_providers.dart</code> 10줄에서 왔습니다. 28줄입니다.",
    chunks=[
        (1, 1, "Hive 패키지.", []),
        (3, 4, "\"오프라인 우선 로컬 저장소\"라는 문서 주석과 클래스. 이름(<code>name</code>)을 주면 그 이름의 Hive 상자(Box)를 열어 돌려줍니다. Hive 상자는 키 → 값을 저장하는 작은 데이터베이스로 생각하면 됩니다(엑셀 시트 하나와 비슷).", []),
        (5, 20, "<b>이 앱이 쓰는 상자 이름 전부.</b> 상자 이름은 각 기능의 저장소가 자기 파일에 따로 들고 있어서(<code>_boxName</code>) 모아 둔 곳이 없었는데, <b>탈퇴할 때 전부 지워야 해서</b> 여기에 한 번 더 적었습니다. 새 상자를 만들면 이 목록에도 추가해야 한다는 주의가 주석에 있고, <code>routines</code>는 루틴을 서버로 옮기기 전 시절의 박스라 지금은 쓰는 코드가 없지만 옛 데이터가 남아 있을 수 있어 계속 지운다는 설명도 있습니다.", ["const"]),
        (22, 22, "<b>상자 열기.</b> <code>Box&lt;Map&gt;</code>은 \"값으로 Map(사전)을 담는 상자\"입니다.", ["generic"]),
        (24, 32, "<b>상자 전부 지우기(탈퇴용).</b> 목록의 상자를 열려 있든 아니든 디스크에서 지웁니다(<code>Hive.deleteBoxFromDisk</code>). 저장소들이 매번 <code>openBox</code>를 부르므로 지운 뒤 다시 읽으면 빈 상자가 새로 만들어집니다.", ["async"]),
    ],
    next_hint="<code>auth_providers.dart</code> 13줄의 <code>LocalAuthSessionRepository</code>로 갑니다.",
))

STOPS.append(dict(
    file="lib/features/auth/data/auth_session_repository.dart",
    title="로그인 토큰 보관함",
    role="세션 저장소",
    arrive="<code>auth_providers.dart</code> 13줄 <code>LocalAuthSessionRepository(...)</code>에서 왔습니다.",
    chunks=[
        (1, 4, "Hive와 우리 저장 도구를 import합니다.", []),
        (5, 9, "<code>abstract class</code>는 약속 목록입니다. \"토큰 읽기·저장·삭제 세 함수가 있어야 한다\"는 것만 적혀 있고 내용은 없습니다. <code>Future&lt;String?&gt;</code>는 \"나중에 문자열 또는 null이 나온다\"입니다.", ["abstract"]),
        (10, 15, "왜 이 저장소가 필요한지 설명하는 문서 주석. 백엔드는 JWT 대신 로그인할 때 준 UUID로 사용자를 알아보고, 그 값을 기기에 들고 있는 것이 이 클래스의 역할입니다.", []),
        (16, 16, "위 약속을 Hive로 실제 구현하는 클래스입니다.", []),
        (17, 18, "생성자. 받은 저장 도구를 <code>_storage</code> 필드에 바로 넣습니다(<code>this._storage</code>).", ["constructor"]),
        (19, 21, "상자 이름 <code>'auth'</code>, 그 안의 키 이름 <code>'access_uuid'</code>. <code>static const</code>는 클래스 전체가 공유하는 고정값입니다.", []),
        (23, 24, "<code>_box</code>를 읽을 때마다 <code>'auth'</code> 상자를 엽니다. Hive는 이미 열린 상자면 바로 돌려줍니다.", ["getter"]),
        (25, 29, "토큰 읽기. 상자를 열고(<code>await</code>), 키로 값을 꺼냅니다. 저장할 때 <code>{'value': uuid}</code>로 감쌌으므로 <code>['value']</code>로 꺼냅니다. 값이 없으면 <code>?.</code> 덕분에 오류 없이 null이 나옵니다.", ["null"]),
        (31, 35, "<b>로그인 성공 시 불리는 함수.</b> 상자에 <code>'access_uuid'</code> → <code>{'value': uuid}</code>로 저장합니다. 앱을 껐다 켜도 남아 있습니다.", []),
        (37, 42, "로그아웃 때 토큰을 지웁니다.", []),
    ],
    next_hint="<code>auth_providers.dart</code> 22줄 <code>ApiClient</code>를 Ctrl+클릭합니다.",
))

STOPS.append(dict(
    file="lib/core/network/api_client.dart",
    title="서버와 대화하는 전화기",
    role="Dio 서버 통신",
    arrive="<code>auth_providers.dart</code> 22줄 <code>ApiClient(getAccessUuid: ...)</code>에서 왔습니다.",
    chunks=[
        (1, 4, "<code>dart:io</code>(어느 운영체제인지 알려 주는 <code>Platform</code>만 가져옴), Dio(HTTP 요청 패키지), 웹인지 알려 주는 <code>kIsWeb</code>.", []),
        (6, 9, "<b>빌드할 때 서버 주소를 바꾸는 방법.</b> <code>flutter run --dart-define=API_BASE_URL=http://192.168.0.10:8080/api/v1</code>처럼 넘기면 그 값이 <code>String.fromEnvironment</code>로 들어옵니다. 안 넘기면 빈 글자입니다. <b>실기기나 다른 사람 PC의 서버</b>를 쓸 때 필요합니다.", ["const"]),
        (11, 18, "<b>서버 주소가 실행 환경마다 다른 이유.</b> 안드로이드 에뮬레이터 안에서는 <code>10.0.2.2</code>가 이 PC의 localhost, iOS 시뮬레이터는 그냥 <code>localhost</code>, 폰 실기기는 같은 와이파이의 PC <b>LAN 주소</b>가 필요합니다(<code>localhost</code>는 폰 자기 자신이라 안 됨).", []),
        (19, 23, "<b>환경에 맞는 주소를 고르는 함수.</b> ① 빌드 때 넘긴 주소가 있으면 그것 ② 안드로이드(웹이 아닐 때)면 <code>10.0.2.2</code> ③ 그 외(iOS 시뮬레이터, 데스크톱)는 <code>localhost</code>. 이전에는 안드로이드 주소 하나가 상수로 박혀 있었습니다.", ["null"]),
        (25, 30, "클래스 설명: 토큰을 어디서 읽는지는 이 클래스가 모르고, 읽는 방법(함수)만 받는다는 내용.", []),
        (31, 32, "생성자. <code>baseUrl</code>(<code>String?</code>)은 <b>안 넘기면 null</b>이고, <code>getAccessUuid</code>는 선택입니다. 로그인 같은 호출은 토큰이 아직 없으니 없어도 됩니다.", ["constructor", "null"]),
        (33, 33, "<code>:</code> 뒤는 \"본문 실행 전에 필드부터 채우기\"(초기화 목록)입니다. <code>baseUrl ?? resolveApiBaseUrl()</code>은 \"넘겼으면 그것을, 아니면 위 함수가 고른 주소를\" 씁니다.", ["null"]),
        (34, 35, "토큰 읽는 함수를 받았다면, 아래를 실행합니다.", []),
        (36, 38, "<b>인터셉터</b>는 요청이 나가기 직전에 끼어드는 검문소입니다. <code>onRequest</code>가 매 요청마다 불립니다.", ["async"]),
        (39, 42, "토큰을 읽어서 있으면 요청 헤더에 <code>X-Access-Uuid: 토큰</code>을 붙입니다. 서버는 이 헤더로 \"누구의 요청인가\"를 압니다.", []),
        (43, 43, "검문 통과, 요청을 계속 보내라.", []),
        (44, 49, "괄호 닫기.", []),
        (50, 52, "필드 두 개. <code>dio</code>는 실제 요청을 보내는 객체, <code>getAccessUuid</code>는 토큰 읽는 함수입니다.", []),
    ],
    next_hint="이제 <code>auth_providers.dart</code> 26줄 <code>ApiAuthRepository</code>, 즉 login_screen 46줄이 부른 <code>.login()</code>의 본체로 갑니다.",
))

STOPS.append(dict(
    file="lib/features/auth/data/auth_repository.dart",
    title="login()의 진짜 내용",
    role="로그인 요청",
    arrive="<code>login_screen.dart</code> 46줄 <code>.login(...)</code> → <code>auth_providers.dart</code> 26줄 <code>ApiAuthRepository</code>에서 왔습니다.",
    chunks=[
        (1, 7, "Dio(예외 타입 <code>DioException</code>), 서버 통신 객체, 오류 변환 함수, 사용자 모델, 세션 저장소를 import합니다.", []),
        (8, 20, "약속 목록. 회원가입, 로그인, 로그아웃 세 기능이 있어야 합니다. <code>{required String email, ...}</code>은 이름을 붙여 꼭 넘겨야 하는 인자입니다. 그래서 login_screen에서 <code>login(email: ..., password: ...)</code>로 불렀습니다.", ["abstract", "constructor"]),
        (21, 25, "이 구현체가 토큰 저장까지 맡는다는 설명. 화면이 \"요청하고, 저장하고\" 두 단계를 챙기지 않아도 되게 하려는 것입니다.", []),
        (26, 30, "Dio로 실제 구현하는 클래스. 조립 공장(<code>auth_providers.dart</code> 26줄)에서 넘겨준 서버 통신 객체와 세션 저장소를 필드에 담습니다.", []),
        (32, 35, "회원가입은 주소만 다르고 로그인과 같은 함수(<code>_authenticate</code>)를 씁니다. 아직 회원가입 화면이 없어 쓰이지 않습니다.", []),
        (37, 40, "<b>login_screen이 부른 함수.</b> 주소 <code>'/auth/login'</code>을 붙여 <code>_authenticate</code>에 넘깁니다.", []),
        (42, 46, "실제 일을 하는 내부 함수. 첫 인자 <code>path</code>는 이름 없이, 나머지는 이름 있는 인자로 받습니다.", ["private"]),
        (47, 51, "<b>서버로 요청 발사.</b> <code>POST /auth/login</code>에 본문 <code>{\"email\": ..., \"password\": ...}</code>를 담아 보냅니다. 이 순간 api_client의 인터셉터(검문소)를 지나갑니다. 응답이 올 때까지 기다립니다.", ["trycatch"]),
        (52, 52, "서버 응답 모양은 <code>{\"data\": {...}, \"error\": null}</code>입니다. 그중 <code>data</code> 부분을 꺼냅니다. <code>as Map&lt;String, dynamic&gt;</code>은 \"이건 사전이라고 보고 다룬다\"는 형 변환입니다.", ["generic"]),
        (53, 53, "<b>서버가 준 토큰(<code>accessUuid</code>)을 기기에 저장합니다.</b> 앞에서 본 <code>saveAccessUuid</code>가 여기서 불립니다. 이후 모든 요청에는 인터셉터가 이 값을 자동으로 붙입니다.", []),
        (54, 54, "응답의 <code>user</code> 부분을 <code>AuthUser</code> 객체로 바꿔 돌려줍니다. 이 값이 login_screen 46줄의 <code>await</code> 결과(<code>user</code>)입니다.", []),
        (55, 58, "요청이 실패하면(서버가 꺼짐, 비밀번호 틀림 등) Dio가 <code>DioException</code>을 던지고, 여기서 잡아 우리 앱의 <code>ApiException</code>으로 바꿔 다시 던집니다. 그래서 login_screen 56줄이 <code>ApiException</code>만 잡으면 됩니다.", []),
        (60, 72, "로그아웃. 서버에 알리고, 실패해도 <code>finally</code>에서 기기 토큰은 반드시 지웁니다. 로그인 흐름에서는 쓰이지 않습니다.", []),
    ],
    next_hint="56줄 <code>throwAsApiException</code>을 Ctrl+클릭해 실패하면 어떻게 되는지 봅니다.",
))

STOPS.append(dict(
    file="lib/core/network/api_exception.dart",
    title="실패를 한국어 메시지로",
    role="오류 변환",
    arrive="<code>auth_repository.dart</code> 56줄 <code>throwAsApiException(e)</code>에서 왔습니다.",
    chunks=[
        (1, 5, "Dio 패키지와 설명 주석. 백엔드가 주는 오류 응답을 앱에서 다루기 쉬운 예외 하나로 바꾼다는 내용입니다.", []),
        (6, 11, "<code>ApiException</code> 클래스. 오류 종류(<code>code</code>, 예: <code>AUTH_INVALID_CREDENTIALS</code>), 사용자에게 보여줄 문구(<code>message</code>), HTTP 상태 번호(<code>statusCode</code>, 예: 401)를 담습니다. <code>implements Exception</code>이라 <code>throw</code>로 던질 수 있습니다.", ["abstract"]),
        (13, 15, "디버그 출력용 문자열. <code>$code</code>처럼 문자열 안의 <code>$</code>는 변수 값을 끼워 넣습니다.", ["arrow"]),
        (16, 20, "아래 함수 설명.", []),
        (21, 22, "반환 타입 <code>Never</code>는 \"이 함수는 절대 정상적으로 끝나지 않고 항상 예외를 던진다\"는 뜻입니다. 서버 응답 본문을 꺼냅니다. 서버에 닿지도 못했으면 <code>response</code>가 null이라 <code>?.</code>로 안전하게 null이 됩니다.", ["null"]),
        (23, 30, "응답에 <code>error</code> 칸이 있으면(서버가 이유를 알려줌) 그 <code>code</code>와 <code>message</code>로 예외를 만들어 던집니다. <code>??</code>는 값이 없을 때 쓸 기본 문구입니다.", []),
        (31, 36, "서버에 아예 닿지 못한 경우(서버가 꺼져 있음, 인터넷 없음). \"서버에 연결할 수 없어요\" 예외를 던집니다. <b>지금 백엔드를 안 켜고 로그인하면 보이는 메시지가 바로 이것입니다.</b>", []),
    ],
    next_hint="<code>auth_repository.dart</code> 54줄로 돌아가 성공했을 때의 <code>AuthUser.fromJson</code>을 봅니다.",
))

STOPS.append(dict(
    file="lib/features/auth/domain/auth_user.dart",
    title="서버 JSON을 앱 객체로",
    role="사용자 모델",
    arrive="<code>auth_repository.dart</code> 54줄 <code>AuthUser.fromJson(...)</code>에서 왔습니다.",
    chunks=[
        (1, 2, "이 모델이 API 문서 몇 장과 같은 모양인지 적은 주석.", []),
        (3, 9, "사용자 한 명을 담는 클래스와 생성자. <code>createdAt</code>만 <code>required</code>가 없어 생략할 수 있습니다.", ["constructor"]),
        (11, 11, "사용자 번호.", []),
        (13, 16, "<b>이름. <code>String?</code>이라 null일 수 있습니다.</b> null이면 아직 온보딩(보호자 이름 입력)을 안 한 계정입니다. 로그인 응답의 <code>user</code>에도 들어 있어서, login_screen 55줄의 분기가 바로 이 값을 봅니다.", ["null"]),
        (18, 21, "이메일, 가입 시각(없을 수 있음). 가입 시각은 로그인 응답에는 없고 <code>GET /users/me</code>에만 있습니다.", []),
        (23, 23, "JSON 사전을 받아 AuthUser를 만드는 생성자.", ["factory"]),
        (24, 27, "사전에서 키로 값을 하나씩 꺼내 필드에 넣습니다. 서버의 <code>\"userId\": 1</code>이 <code>userId: 1</code>이 됩니다.", []),
        (28, 30, "가입 시각은 없으면 null, 있으면 문자열(<code>\"2026-09-01T08:30:00Z\"</code>)을 <code>DateTime</code>으로 바꿉니다.", []),
        (31, 33, "괄호 닫기.", []),
    ],
    next_hint="로그인 흐름은 여기서 끝입니다. 이 <code>AuthUser</code>를 돌려주는 또 하나의 요청, <code>user_repository.dart</code>의 <code>getMe()</code>를 봅니다(프로필 등 다른 화면이 씁니다).",
))

STOPS.append(dict(
    file="lib/features/auth/data/user_repository.dart",
    title="내 정보 받아오기, 그리고 분기",
    role="내 정보 요청",
    arrive="<code>auth_user.dart</code>의 <code>AuthUser</code>를 돌려주는 또 다른 요청입니다. 로그인 화면은 더 이상 부르지 않고, 내 정보를 보여주는 화면들이 씁니다.",
    chunks=[
        (1, 6, "import. auth_repository와 같은 재료입니다.", []),
        (7, 21, "약속 목록: 내 정보 조회(<code>getMe</code>), 이름 수정(<code>updateMe</code>), <b>회원 탈퇴(<code>deleteUser</code>)</b>. 탈퇴 쪽 주석은 서버가 하는 일과, 기기 안 정리는 이 저장소 일이 아니라는 선을 설명합니다.", ["abstract"]),
        (23, 26, "Dio 구현체. 서버 통신 객체 하나만 있으면 됩니다.", []),
        (28, 36, "<b>GET /users/me</b> 요청을 보내고(인터셉터가 방금 저장한 토큰을 붙여줌), 응답의 <code>data</code>를 <code>AuthUser</code>로 바꿔 돌려줍니다. 실패하면 <code>ApiException</code>으로 바꿔 던집니다. 로그인 응답에는 없던 <code>createdAt</code>까지 들어 있습니다.", []),
        (38, 46, "이름 수정(<code>PATCH /users/me</code>). 온보딩 1단계와 프로필 수정 화면에서 씁니다.", []),
        (48, 56, "<b>탈퇴(<code>DELETE /users/me</code>).</b> 본문 없이 204가 오므로 돌려줄 값이 없습니다(<code>Future&lt;void&gt;</code>). 5장 <code>account_actions.dart</code>가 이것을 부릅니다.", []),
    ],
    next_hint="1장 끝. 로그인 화면은 <code>login()</code>이 돌려준 <code>user.name</code>만 보고 온보딩 또는 홈으로 갑니다.",
))

# 2~5장은 파일이 커서 따로 나눠 두었다. 각 파일은 CONCEPTS_CH(새 개념)와
# STOPS_CH(정류장 목록, 각각 "chapter" 키 포함)를 정의한다.
import importlib as _il
for _mod in ("spec_ch2", "spec_ch3", "spec_ch4", "spec_ch5"):
    try:
        _m = _il.import_module(_mod)
    except ModuleNotFoundError:
        continue
    CONCEPTS.update(_m.CONCEPTS_CH)
    STOPS.extend(_m.STOPS_CH)
