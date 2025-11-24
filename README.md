<!--TÍTULO-->
# Sistema Poliedro Professores


<!--DESCRIÇÃO-->
<!-- > Site desenvolvido para a entidade Mauá Esports.<br/>
<!-- > O site consiste em centralizar e facilitar a administração das atividades esportivas, incluindo a gestão dos horários de treino, das horas PAE dos alunos e das informações sobre os times e campeonatos.


<!--STATUS-->
## Status
> ✔ Concluído.


<!--FUNCIONALIDADES-->
<!-- ## Funcionalidades 
````

````


<!--TECNOLOGIAS-->
<!-- ## Tecnologias


<!--PROTÓTIPO-->
<!-- ## Protótipo


<!--PARTICIPANTES-->
## Participantes
| Nome                            | RA         |
|---------------------------------|------------|
| Alvaro Nogueira Junqueira Souza	| 24.01402-8 |
| Antônio Vítor Bozzo de Napoli   | 24.00086-8 |
| Felipe Brito Moulin Rodrigues   | 24.01680-2 |
| Guilherme Viana Fim             | 24.00689-0 |
| Luan Camara Lopes	              | 24.00376-0 |
| Victor Hugo Gaetano Oliveira Tavares de Pinho | 24.00947-4 |


<!--DEPENDÊNCIAS-->
<!-- ## Dependência
````
````


<!--COMO UTILIZAR-->
<!-- ## Como Utilizar
```
```


<!--COMO RODAR TESTES-->
<!-- ## Como Rodar os testes
```
```


<!--CONTRIBUIÇÃO-->
<!-- ## Contribuição
````
````


<!--ESTRUTURA DE PASTAS-->
## Estrutura de Pastas
````
├── README.md
├── LICENSE
├── backend/
│   ├── jest.config.cjs
│   ├── package.json
│   ├── server.cjs
│   ├── coverage/
│   │   ├── clover.xml
│   │   ├── coverage-final.json
│   │   ├── lcov.info
│   │   └── lcov-report/
│   │       ├── base.css
│   │       ├── block-navigation.js
│   │       ├── index.html
│   │       ├── prettify.css
│   │       ├── prettify.js
│   │       └── sorter.js
│   ├── middleware/
│   │   └── auth.cjs
│   ├── models/
│   │   ├── aluno.cjs
│   │   ├── cardDisciplina.cjs
│   │   ├── codigoVerificacao.cjs
│   │   ├── notas.cjs
│   │   └── professor.cjs
│   ├── routes/
│   │   ├── rotaAluno.cjs
│   │   ├── rotaProfessor.cjs
│   │   ├── cards/
│   │   │   └── disciplinas.cjs
│   │   ├── disciplina/
│   │   │   ├── materiais.cjs
│   │   │   └── topicos.cjs
│   │   └── recuperacao_senha/
│   │       ├── enviarEmail.cjs
│   │       ├── recuperarSenha.cjs
│   │       └── redis.cjs
│   └── tests/
│       ├── setup.cjs
│       ├── integration/
│       │   ├── alunos.test.cjs
│       │   ├── disciplinas.test.cjs
│       │   ├── email.test.cjs
│       │   ├── materiais.test.cjs
│       │   ├── professores.test.cjs
│       │   └── topicos.test.cjs
│       └── unit/
│           ├── auth.test.cjs
│           └── utils.test.cjs
└── sistema_poliedro/
    ├── README.md
    ├── analysis_options.yaml
    ├── devtools_options.yaml
    ├── pubspec.lock
    ├── pubspec.yaml
    ├── .metadata
    ├── android/
    │   ├── build.gradle.kts
    │   ├── gradle.properties
    │   ├── settings.gradle.kts
    │   ├── app/
    │   │   ├── build.gradle.kts
    │   │   └── src/
    │   │       ├── debug/
    │   │       │   └── AndroidManifest.xml
    │   │       ├── main/
    │   │       │   ├── AndroidManifest.xml
    │   │       │   ├── kotlin/
    │   │       │   │   └── com/
    │   │       │   │       └── example/
    │   │       │   │           └── sistema_poliedro/
    │   │       │   │               └── MainActivity.kt
    │   │       │   └── res/
    │   │       │       ├── drawable/
    │   │       │       │   └── launch_background.xml
    │   │       │       ├── drawable-v21/
    │   │       │       │   └── launch_background.xml
    │   │       │       ├── values/
    │   │       │       │   └── styles.xml
    │   │       │       ├── values-night/
    │   │       │       │   └── styles.xml
    │   │       │       └── xml/
    │   │       │           └── file_paths.xml
    │   │       └── profile/
    │   │           └── AndroidManifest.xml
    │   └── gradle/
    │       └── wrapper/
    │           └── gradle-wrapper.properties
    ├── ios/
    │   ├── Podfile
    │   ├── Flutter/
    │   │   ├── AppFrameworkInfo.plist
    │   │   ├── Debug.xcconfig
    │   │   └── Release.xcconfig
    │   ├── Runner/
    │   │   ├── AppDelegate.swift
    │   │   ├── Info.plist
    │   │   ├── Runner-Bridging-Header.h
    │   │   ├── Assets.xcassets/
    │   │   │   ├── AppIcon.appiconset/
    │   │   │   │   └── Contents.json
    │   │   │   └── LaunchImage.imageset/
    │   │   │       ├── README.md
    │   │   │       └── Contents.json
    │   │   └── Base.lproj/
    │   │       ├── LaunchScreen.storyboard
    │   │       └── Main.storyboard
    │   └── RunnerTests/
    │       └── RunnerTests.swift
    ├── lib/
    │   ├── main.dart
    │   └── src/
    │       ├── components/
    │       │   ├── adaptive_navigation.dart
    │       │   ├── alerta.dart
    │       │   ├── animated_card_button.dart
    │       │   ├── auth_guard.dart
    │       │   ├── botao_voltar.dart
    │       │   ├── card_notas.dart
    │       │   ├── disciplina_card.dart
    │       │   └── lista_disciplinas.dart
    │       ├── dialogs/
    │       │   ├── adicionar_card_dialog.dart
    │       │   ├── adicionar_material_dialog.dart
    │       │   ├── adicionar_topico_dialog.dart
    │       │   └── editar_card_dialog.dart
    │       ├── models/
    │       │   ├── modelo_card_disciplina.dart
    │       │   └── modelo_usuario.dart
    │       ├── pages/
    │       │   ├── perfil_page.dart
    │       │   ├── aluno/
    │       │   │   ├── calendario_aluno_page.dart
    │       │   │   ├── notas_aluno_page.dart
    │       │   │   ├── notificacoes_aluno_page.dart
    │       │   │   ├── page_controller.dart
    │       │   │   └── disciplina/
    │       │   │       ├── disciplinas_page.dart
    │       │   │       └── tasks_page.dart
    │       │   ├── login/
    │       │   │   ├── codigo_verificacao.dart
    │       │   │   ├── login_page.dart
    │       │   │   ├── nova_senha.dart
    │       │   │   └── Recuperar_Senha.dart
    │       │   └── professor/
    │       │       ├── calendario_professor_page.dart
    │       │       ├── home_professor.dart
    │       │       ├── notas_professor_page.dart
    │       │       ├── notificacoes_professor_page.dart
    │       │       └── disciplina/
    │       │           ├── disciplinas_page.dart
    │       │           └── tasks_page.dart
    │       ├── services/
    │       │   ├── auth_service.dart
    │       │   ├── calculadora_medias.dart
    │       │   ├── card_disciplina_service.dart
    │       │   ├── material_service.dart
    │       │   ├── permission_service.dart
    │       │   ├── topico_service.dart
    │       │   └── user_service.dart
    │       ├── styles/
    │       │   ├── cores.dart
    │       │   └── fontes.dart
    │       └── utils/
    │           └── image_utils.dart
    ├── linux/
    │   ├── CMakeLists.txt
    │   ├── flutter/
    │   │   ├── CMakeLists.txt
    │   │   ├── generated_plugin_registrant.cc
    │   │   ├── generated_plugin_registrant.h
    │   │   └── generated_plugins.cmake
    │   └── runner/
    │       ├── CMakeLists.txt
    │       ├── main.cc
    │       ├── my_application.cc
    │       └── my_application.h
    ├── macos/
    │   ├── Podfile
    │   ├── Podfile.lock
    │   ├── Flutter/
    │   │   ├── Flutter-Debug.xcconfig
    │   │   ├── Flutter-Release.xcconfig
    │   │   └── GeneratedPluginRegistrant.swift
    │   ├── Runner/
    │   │   ├── AppDelegate.swift
    │   │   ├── DebugProfile.entitlements
    │   │   ├── Info.plist
    │   │   ├── MainFlutterWindow.swift
    │   │   ├── Release.entitlements
    │   │   ├── Assets.xcassets/
    │   │   │   └── AppIcon.appiconset/
    │   │   │       └── Contents.json
    │   │   ├── Base.lproj/
    │   │   │   └── MainMenu.xib
    │   │   └── Configs/
    │   │       ├── AppInfo.xcconfig
    │   │       ├── Debug.xcconfig
    │   │       ├── Release.xcconfig
    │   │       └── Warnings.xcconfig
    │   └── RunnerTests/
    │       └── RunnerTests.swift
    ├── test/
    │   └── widget_test.dart
    ├── web/
    │   ├── index.html
    │   └── manifest.json
    └── windows/
        ├── CMakeLists.txt
        ├── flutter/
        │   ├── CMakeLists.txt
        │   ├── generated_plugin_registrant.cc
        │   ├── generated_plugin_registrant.h
        │   └── generated_plugins.cmake
        └── runner/
            ├── CMakeLists.txt
            ├── flutter_window.cpp
            ├── flutter_window.h
            ├── main.cpp
            ├── resource.h
            ├── runner.exe.manifest
            ├── Runner.rc
            ├── utils.cpp
            ├── utils.h
            ├── win32_window.cpp
            └── win32_window.h
````


<!--ESTATÍSTICAS-->
## Estatísticas
![](https://visitor-badge.laobi.icu/badge?page_id=antonioVitor04.S4-Poliedro-Sistema-Para-Professores)
![Tamanho do Repositório](https://img.shields.io/github/repo-size/antonioVitor04/S4-Poliedro-Sistema-Para-Professores)
![Linguagens](https://img.shields.io/github/languages/top/antonioVitor04/S4-Poliedro-Sistema-Para-Professores)


<!--LICENÇA-->
## Licença
[Veja a licença](https://github.com/antonioVitor04/S4-Poliedro-Sistema-Para-Professores?tab=License-1-ov-file)
