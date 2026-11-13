import '../../domain/entities/models.dart';

class MockSenatiRepository {
  static List<GroupEntity> getInitialGroups() {
    return const [
      GroupEntity(
        id: 'GRP-01',
        nrcCode: 'NRC-48210',
        courseName: 'Desarrollo de Aplicaciones Móviles Multiplataforma',
        career: 'Ingeniería de Software con IA',
        semester: 'V Semestre',
        schedule: 'Lun / Mié 08:00 - 12:15',
        classroom: 'Lab. ETI-302',
      ),
      GroupEntity(
        id: 'GRP-02',
        nrcCode: 'NRC-48215',
        courseName: 'Arquitectura de Servicios Web con ASP.NET Core',
        career: 'Ingeniería de Software con IA',
        semester: 'V Semestre',
        schedule: 'Mar / Jue 14:00 - 18:15',
        classroom: 'Lab. ETI-204',
      ),
      GroupEntity(
        id: 'GRP-03',
        nrcCode: 'NRC-49104',
        courseName: 'Base de Datos Avanzada y Cloud Computing',
        career: 'Diseño y Desarrollo Web',
        semester: 'IV Semestre',
        schedule: 'Vie 08:00 - 13:30',
        classroom: 'Lab. ETI-108',
      ),
      GroupEntity(
        id: 'GRP-04',
        nrcCode: 'NRC-50312',
        courseName: 'Seguridad Informática en Aplicaciones Empresariales',
        career: 'Ciberseguridad y Redes',
        semester: 'VI Semestre',
        schedule: 'Sáb 08:00 - 12:30',
        classroom: 'Aula Virtual / Lab 401',
      ),
    ];
  }

  static List<SessionEntity> getInitialSessions() {
    return [
      SessionEntity(
        id: 'SES-101',
        groupId: 'GRP-01',
        sessionNumber: 1,
        topic: 'Arquitectura Limpia (Clean Architecture) en Flutter',
        date: DateTime(2026, 11, 2),
        type: SessionType.teoria,
      ),
      SessionEntity(
        id: 'SES-102',
        groupId: 'GRP-01',
        sessionNumber: 2,
        topic: 'Diseño Responsivo y Gestión de Estado Reactivo',
        date: DateTime(2026, 11, 9),
        type: SessionType.laboratorio,
      ),
      SessionEntity(
        id: 'SES-103',
        groupId: 'GRP-01',
        sessionNumber: 3,
        topic: 'Persistencia Offline-First y Sincronización REST',
        date: DateTime(2026, 11, 13),
        type: SessionType.laboratorio,
      ),
      SessionEntity(
        id: 'SES-201',
        groupId: 'GRP-02',
        sessionNumber: 1,
        topic: 'Diseño de Web APIs RESTful con .NET 8 y Minimal APIs',
        date: DateTime(2026, 11, 5),
        type: SessionType.teoria,
      ),
      SessionEntity(
        id: 'SES-202',
        groupId: 'GRP-02',
        sessionNumber: 2,
        topic: 'Autenticación JWT y Control de Roles Institucionales',
        date: DateTime(2026, 11, 12),
        type: SessionType.laboratorio,
      ),
      SessionEntity(
        id: 'SES-301',
        groupId: 'GRP-03',
        sessionNumber: 1,
        topic: 'Optimización de Índices y Procedimientos Almacenados SQL',
        date: DateTime(2026, 11, 6),
        type: SessionType.laboratorio,
      ),
      SessionEntity(
        id: 'SES-401',
        groupId: 'GRP-04',
        sessionNumber: 1,
        topic: 'Mitigación de Vulnerabilidades OWASP Top 10',
        date: DateTime(2026, 11, 7),
        type: SessionType.seminario,
      ),
    ];
  }

  static List<StudentEntity> getInitialStudents() {
    return const [
      // GRP-01 Students
      StudentEntity(
        id: 'STU-01',
        senatiCode: '001458921',
        fullName: 'Quispe Mamani, Alejandro Gabriel',
        groupId: 'GRP-01',
        specialty: 'Ing. de Software con IA',
      ),
      StudentEntity(
        id: 'STU-02',
        senatiCode: '001458934',
        fullName: 'Rojas Huamán, Valeria Fernanda',
        groupId: 'GRP-01',
        specialty: 'Ing. de Software con IA',
      ),
      StudentEntity(
        id: 'STU-03',
        senatiCode: '001459012',
        fullName: 'Mendoza Chávez, Diego Sebastián',
        groupId: 'GRP-01',
        specialty: 'Ing. de Software con IA',
      ),
      StudentEntity(
        id: 'STU-04',
        senatiCode: '001459105',
        fullName: 'Flores Paredes, Camila Lucía',
        groupId: 'GRP-01',
        specialty: 'Ing. de Software con IA',
      ),
      StudentEntity(
        id: 'STU-05',
        senatiCode: '001459218',
        fullName: 'Vargas Salazar, Mateo Nicolás',
        groupId: 'GRP-01',
        specialty: 'Ing. de Software con IA',
      ),
      StudentEntity(
        id: 'STU-06',
        senatiCode: '001459340',
        fullName: 'Castillo Gutiérrez, Luciana Sofía',
        groupId: 'GRP-01',
        specialty: 'Ing. de Software con IA',
      ),
      StudentEntity(
        id: 'STU-07',
        senatiCode: '001459401',
        fullName: 'Palomino Cárdenas, Joaquín Andrés',
        groupId: 'GRP-01',
        specialty: 'Ing. de Software con IA',
      ),
      StudentEntity(
        id: 'STU-08',
        senatiCode: '001459519',
        fullName: 'Aguilar Ramos, Daniela Ximena',
        groupId: 'GRP-01',
        specialty: 'Ing. de Software con IA',
      ),

      // GRP-02 Students
      StudentEntity(
        id: 'STU-09',
        senatiCode: '001460110',
        fullName: 'Sánchez Medina, Rodrigo Alonso',
        groupId: 'GRP-02',
        specialty: 'Ing. de Software con IA',
      ),
      StudentEntity(
        id: 'STU-10',
        senatiCode: '001460245',
        fullName: 'Cruzado Villanueva, Ariana Belén',
        groupId: 'GRP-02',
        specialty: 'Ing. de Software con IA',
      ),
      StudentEntity(
        id: 'STU-11',
        senatiCode: '001460319',
        fullName: 'Espinoza Torres, Leonardo Fabián',
        groupId: 'GRP-02',
        specialty: 'Ing. de Software con IA',
      ),
      StudentEntity(
        id: 'STU-12',
        senatiCode: '001460488',
        fullName: 'Navarro Peña, Antonella Milagros',
        groupId: 'GRP-02',
        specialty: 'Ing. de Software con IA',
      ),
      StudentEntity(
        id: 'STU-13',
        senatiCode: '001460512',
        fullName: 'Delgado Lozano, Bruno Renato',
        groupId: 'GRP-02',
        specialty: 'Ing. de Software con IA',
      ),

      // GRP-03 Students
      StudentEntity(
        id: 'STU-14',
        senatiCode: '001471002',
        fullName: 'Benites Acosta, Gianmarco David',
        groupId: 'GRP-03',
        specialty: 'Diseño y Desarrollo Web',
      ),
      StudentEntity(
        id: 'STU-15',
        senatiCode: '001471108',
        fullName: 'Carrasco Mejía, Fiorella Pierina',
        groupId: 'GRP-03',
        specialty: 'Diseño y Desarrollo Web',
      ),
      StudentEntity(
        id: 'STU-16',
        senatiCode: '001471215',
        fullName: 'Zevallos Ponce, Héctor Manuel',
        groupId: 'GRP-03',
        specialty: 'Diseño y Desarrollo Web',
      ),
      StudentEntity(
        id: 'STU-17',
        senatiCode: '001471390',
        fullName: 'Valdivia Ríos, Natalia Alejandra',
        groupId: 'GRP-03',
        specialty: 'Diseño y Desarrollo Web',
      ),

      // GRP-04 Students
      StudentEntity(
        id: 'STU-18',
        senatiCode: '001482011',
        fullName: 'Huerta Zambrano, Christian Joel',
        groupId: 'GRP-04',
        specialty: 'Ciberseguridad y Redes',
      ),
      StudentEntity(
        id: 'STU-19',
        senatiCode: '001482114',
        fullName: 'Ochoa Miranda, Valeria Estefanía',
        groupId: 'GRP-04',
        specialty: 'Ciberseguridad y Redes',
      ),
      StudentEntity(
        id: 'STU-20',
        senatiCode: '001482299',
        fullName: 'Chambi Condori, Jhonatan Emerson',
        groupId: 'GRP-04',
        specialty: 'Ciberseguridad y Redes',
      ),
    ];
  }

  static List<String> getPredefinedActivities() {
    return const [
      'Participación en clase',
      'Resolución de reto en laboratorio',
      'Apoyo colaborativo a compañeros',
      'Respuesta destacada / Pregunta técnica',
      'Exposición de avance de proyecto',
    ];
  }
}
