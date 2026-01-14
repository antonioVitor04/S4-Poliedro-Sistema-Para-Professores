<!--TÍTULO-->
# Sistema Professores


<!--DESCRIÇÃO-->
> Sistema desenvolvido para grupo educacional Poliedro.<br/>
> O sistema consiste em centralizar e facilitar a gestão escolar, permitindo que professores gerenciem disciplinas, notas, calendário e notificações, enquanto os alunos acessam para consultar e realizar ações em suas atividades acadêmicas.


<!--STATUS-->
## Status
> ✔ Concluído.


<!--FUNCIONALIDADES-->
## Funcionalidades 
````
Aluno:
    . Editar Perfil
    . Visualizar Disciplinas
    . Visualizar Notas
    . Visualizar Calendário
    . Visualizar Notificações  

Professor:
    . Editar Perfil
    . Visualizar/Editar Disciplinas
    . Visualizar/Editar Notas
    . Visualizar Calendário
    . Visualizar/Editar Notificações  
````


<!--TECNOLOGIAS-->
## Tecnologias
| <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/dart/dart-original.svg" width="40"/> | <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/flutter/flutter-original.svg" width="40"/> | <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/nodejs/nodejs-original.svg" width="40"/> | <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/mongodb/mongodb-original.svg" width="40"/> | <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/azure/azure-original.svg" width="40"/> | <img src="https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/figma/figma-original.svg" width="40"/> |
| ---------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------ | -------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------- |
| Dart | Flutter | Node.js | MongoDB | Azure | Figma |


<!--PROTÓTIPO-->
## Protótipo
[![](https://img.shields.io/badge/Figma--5C5C5C?logo=figma&logoColor=white)](https://www.figma.com/design/A38hkySKBNvDWGq5ktC5ja/S4-Sistema-Professores?node-id=1780-4&t=HvTRYiFBOmca62RD-1)


<!--PARTICIPANTES-->
## Participantes
| Nome                            |
|---------------------------------|
| Alvaro Nogueira Junqueira Souza |
| Antônio Vítor Bozzo de Napoli   |
| Felipe Brito Moulin Rodrigues   |
| Guilherme Viana Fim             |
| Luan Camara Lopes	              |
| Victor Hugo Pinho               | 


<!--DEPENDÊNCIAS-->
## Dependência
````
bcrypt       | ^6.0.0  | Hashing de senhas para segurança
cors         | ^2.8.5  | Habilita CORS para requisições entre origens
dotenv       | ^17.2.2 | Gerenciamento de variáveis de ambiente
express      | ^5.1.0  | Framework para criação de servidores web e APIs
jsonwebtoken | ^9.0.2  | Geração e verificação de tokens JWT
mongoose     | ^8.18.2 | ODM para trabalhar com MongoDB em Node.js
multer       | ^2.0.2  | Middleware para upload de arquivos em Node.js
````


<!--COMO UTILIZAR-->
## Como Utilizar
```
Requisitos:
    . Node.js 18+ para executar o backend
    . npm como gerenciador de pacotes
    . MongoDB 5.0+ para banco de dados NoSQL
    . Flutter SDK 3.10+ para executar o frontend
    . Dart SDK (incluso no Flutter)
    . IDE (VS Code recomendado)

Execução:
    1. Clone o repositório                          | git clone https://github.com/antonioVitor04/S4-Poliedro-Sistema-Para-Professores

    2. Navegue até o diretório do projeto           | cd S4-Poliedro-Sistema-Para-Professores

    3. Instale as dependências do backend           | cd backend
                                                    | npm install

    4. Configure as variáveis de ambiente           | PORT=3000
                                                    | MONGO_URI=mongodb://localhost:27017/nome-do-banco

    5. Inicialize o backend                         | npm run dev

    6. Execute o frontend (Flutter)                 | sistema_poliedro
                                                    | flutter pub get
                                                    | flutter run
```


<!--CONTRIBUIÇÃO-->
## Contribuição
````
1. Fork               | Crie uma cópia do repositório no seu perfil

2. Clone              | git clone https://github.com/antonioVitor04/S4-Poliedro-Sistema-Para-Professores

3. Crie uma Branch    | git checkout -b minha-branch

4. Faça as Alterações | Edite os arquivos e teste.

5. Commit e Push      | git add .
                      |	git commit -m "Descrição das alterações" 
                      |	git push origin minha-branch

6. Pull Request       | Solicite a inclusão de suas mudanças no repositório original.
````


<!--ESTRUTURA DE PASTAS-->
## Estrutura de Pastas

````
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
│   │   ├── auth.cjs
│   │   ├── comentarioAuth.cjs
│   │   └── disciplinaAuth.cjs
│   ├── models/
│   │   ├── aluno.cjs
│   │   ├── cardDisciplina.cjs
│   │   ├── codigoVerificacao.cjs
│   │   ├── comentario.cjs
│   │   ├── nota.cjs
│   │   ├── notificacoes.cjs
│   │   └── professor.cjs
│   ├── routes/
│   │   ├── notas.cjs
│   │   ├── notificacoes.cjs
│   │   ├── rotaAluno.cjs
│   │   ├── rotaProfessor.cjs
│   │   ├── cards/
│   │   │   └── disciplinas.cjs
│   │   ├── disciplina/
│   │   │   ├── comentarios.cjs
│   │   │   ├── materiais.cjs
│   │   │   └── topicos.cjs
│   │   └── recuperacao_senha/
│   │       ├── enviarEmail.cjs
│   │       ├── recuperarSenha.cjs
│   │       └── redis.cjs
│   └── tests/
│       ├── setup.cjs
│       ├── helpers/
│       │   ├── authHelper.cjs
│       │   └── transactionHelper.cjs
│       ├── integration/
│       │   ├── alunos.test.cjs
│       │   ├── comentarios.test.cjs
│       │   ├── disciplinas.test.cjs
│       │   ├── email.test.cjs
│       │   ├── materiais.test.cjs
│       │   ├── notas.test.cjs
│       │   ├── notificacoes.test.cjs
│       │   ├── professores.test.cjs
│       │   └── topicos.test.cjs
│       └── unit/
│           ├── auth.test.cjs
│           └── utils.test.cjs
├── sistema_poliedro/
│    ├── README.md
│    ├── analysis_options.yaml
│    ├── devtools_options.yaml
│    ├── pubspec.lock
│    ├── pubspec.yaml
│    ├── .metadata
│    ├── android/
│    │   ├── build.gradle.kts
│    │   ├── gradle.properties
│    │   ├── settings.gradle.kts
│    │   ├── app/
│    │   │   ├── build.gradle.kts
│    │   │   └── src/
│    │   │       ├── debug/
│    │   │       │   └── AndroidManifest.xml
│    │   │       ├── main/
│    │   │       │   ├── AndroidManifest.xml
│    │   │       │   ├── kotlin/
│    │   │       │   │   └── com/
│    │   │       │   │       └── example/
│    │   │       │   │           └── sistema_poliedro/
│    │   │       │   │               └── MainActivity.kt
│    │   │       │   └── res/
│    │   │       │       ├── drawable/
│    │   │       │       │   └── launch_background.xml
│    │   │       │       ├── drawable-v21/
│    │   │       │       │   └── launch_background.xml
│    │   │       │       ├── values/
│    │   │       │       │   └── styles.xml
│    │   │       │       ├── values-night/
│    │   │       │       │   └── styles.xml
│    │   │       │       └── xml/
│    │   │       │           └── file_paths.xml
│    │   │       └── profile/
│    │   │           └── AndroidManifest.xml
│    │   └── gradle/
│    │       └── wrapper/
│    │           └── gradle-wrapper.properties
│    ├── ios/
│    │   ├── Podfile
│    │   ├── Flutter/
│    │   │   ├── AppFrameworkInfo.plist
│    │   │   ├── Debug.xcconfig
│    │   │   └── Release.xcconfig
│    │   ├── Runner/
│    │   │   ├── AppDelegate.swift
│    │   │   ├── Info.plist
│    │   │   ├── Runner-Bridging-Header.h
│    │   │   ├── Assets.xcassets/
│    │   │   │   ├── AppIcon.appiconset/
│    │   │   │   │   └── Contents.json
│    │   │   │   └── LaunchImage.imageset/
│    │   │   │       ├── README.md
│    │   │   │       └── Contents.json
│    │   │   └── Base.lproj/
│    │   │       ├── LaunchScreen.storyboard
│    │   │       └── Main.storyboard
│    │   └── RunnerTests/
│    │       └── RunnerTests.swift
│    ├── lib/
│    │   ├── main.dart
│    │   └── src/
│    │       ├── components/
│    │       │   ├── adaptive_navigation.dart
│    │       │   ├── alerta.dart
│    │       │   ├── animated_card_button.dart
│    │       │   ├── auth_guard.dart
│    │       │   ├── bell_with_badge.dart
│    │       │   ├── botao_voltar.dart
│    │       │   ├── card_notas.dart
│    │       │   ├── disciplina_card.dart
│    │       │   └── lista_disciplinas.dart
│    │       ├── dialogs/
│    │       │   ├── adicionar_card_dialog.dart
│    │       │   ├── adicionar_material_dialog.dart
│    │       │   ├── adicionar_topico_dialog.dart
│    │       │   ├── editar_card_dialog.dart
│    │       │   ├── editar_material_dialog.dart
│    │       │   ├── editar_perfil_dialog.dart
│    │       │   └── gerenciar_relacionamentos_dialog.dart
│    │       ├── models/
│    │       │   ├── mensagem_model.dart
│    │       │   ├── modelo_avaliacao.dart
│    │       │   ├── modelo_card_disciplina.dart
│    │       │   ├── modelo_comentario.dart
│    │       │   ├── modelo_disciplina.dart
│    │       │   ├── modelo_nota.dart
│    │       │   └── modelo_usuario.dart
│    │       ├── pages/
│    │       │   ├── perfil_page.dart
│    │       │   ├── aluno/
│    │       │   │   ├── calendario_aluno_page.dart
│    │       │   │   ├── notas_aluno_page.dart
│    │       │   │   ├── notificacoes_aluno_page.dart
│    │       │   │   ├── page_aluno_controller.dart
│    │       │   │   └── disciplina/
│    │       │   │       ├── disciplina_detail_page.dart
│    │       │   │       ├── disciplinas_page.dart
│    │       │   │       └── tasks_page.dart
│    │       │   ├── login/
│    │       │   │   ├── codigo_verificacao.dart
│    │       │   │   ├── login_page.dart
│    │       │   │   ├── nova_senha.dart
│    │       │   │   └── Recuperar_Senha.dart
│    │       │   └── professor/
│    │       │       ├── calendario_professor_page.dart
│    │       │       ├── notas.dart
│    │       │       ├── notificacoes_professor_page.dart
│    │       │       ├── page_professor_controller.dart
│    │       │       └── disciplina/
│    │       │           ├── disciplinas_page.dart
│    │       │           └── tasks_page.dart
│    │       ├── services/
│    │       │   ├── auth_service.dart
│    │       │   ├── calculadora_medias.dart
│    │       │   ├── card_disciplina_service.dart
│    │       │   ├── comentario_service.dart
│    │       │   ├── material_service.dart
│    │       │   ├── mensagens_prof_service.dart
│    │       │   ├── notas_service.dart
│    │       │   ├── notificacoes_service.dart
│    │       │   ├── permission_service.dart
│    │       │   ├── topico_service.dart
│    │       │   └── user_service.dart
│    │       ├── styles/
│    │       │   ├── cores.dart
│    │       │   └── fontes.dart
│    │       └── utils/
│    │           └── image_utils.dart
│    ├── linux/
│    │   ├── CMakeLists.txt
│    │   ├── flutter/
│    │   │   ├── CMakeLists.txt
│    │   │   ├── generated_plugin_registrant.cc
│    │   │   ├── generated_plugin_registrant.h
│    │   │   └── generated_plugins.cmake
│    │   └── runner/
│    │       ├── CMakeLists.txt
│    │       ├── main.cc
│    │       ├── my_application.cc
│    │       └── my_application.h
│    ├── macos/
│    │   ├── Podfile
│    │   ├── Podfile.lock
│    │   ├── Flutter/
│    │   │   ├── Flutter-Debug.xcconfig
│    │   │   ├── Flutter-Release.xcconfig
│    │   │   └── GeneratedPluginRegistrant.swift
│    │   ├── Runner/
│    │   │   ├── AppDelegate.swift
│    │   │   ├── DebugProfile.entitlements
│    │   │   ├── Info.plist
│    │   │   ├── MainFlutterWindow.swift
│    │   │   ├── Release.entitlements
│    │   │   ├── Assets.xcassets/
│    │   │   │   └── AppIcon.appiconset/
│    │   │   │       └── Contents.json
│    │   │   ├── Base.lproj/
│    │   │   │   └── MainMenu.xib
│    │   │   └── Configs/
│    │   │       ├── AppInfo.xcconfig
│    │   │       ├── Debug.xcconfig
│    │   │       ├── Release.xcconfig
│    │   │       └── Warnings.xcconfig
│    │   └── RunnerTests/
│    │       └── RunnerTests.swift
│    ├── test/
│    │   └── widget_test.dart
│    ├── web/
│    │   ├── index.html
│    │   └── manifest.json
│    └── windows/
│        ├── CMakeLists.txt
│        ├── flutter/
│        │   ├── CMakeLists.txt
│        │   ├── generated_plugin_registrant.cc
│        │   ├── generated_plugin_registrant.h
│        │   └── generated_plugins.cmake
│        └── runner/
│            ├── CMakeLists.txt
│            ├── flutter_window.cpp
│            ├── flutter_window.h
│            ├── main.cpp
│            ├── resource.h
│            ├── runner.exe.manifest
│            ├── Runner.rc
│            ├── utils.cpp
│            ├── utils.h
│            ├── win32_window.cpp
│            └── win32_window.h
├── .DS_Store
├── LICENSE
├── README.md
````


<!--ESTATÍSTICAS-->
## Estatísticas
![](https://visitor-badge.laobi.icu/badge?page_id=antonioVitor04.S4-Poliedro-Sistema-Para-Professores)
![Tamanho do Repositório](https://img.shields.io/github/repo-size/antonioVitor04/S4-Poliedro-Sistema-Para-Professores)
![Linguagens](https://img.shields.io/github/languages/top/antonioVitor04/S4-Poliedro-Sistema-Para-Professores)


<!--LICENÇA-->
## Licença
[Veja a licença](https://github.com/antonioVitor04/S4-Poliedro-Sistema-Para-Professores?tab=License-1-ov-file)
