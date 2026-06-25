import 'package:flutter_test/flutter_test.dart';
import 'package:v2mem_clinic/core/auth/auth_session.dart';
import 'package:v2mem_clinic/core/constants/app_roles.dart';
import 'package:v2mem_clinic/features/timeline/data/timeline_event_navigation.dart';
import 'package:v2mem_clinic/features/timeline/models/timeline_event.dart';
import 'package:v2mem_clinic/features/timeline/models/timeline_event_enums.dart';
import 'package:v2mem_clinic/shared/models/app_user.dart';

void main() {
  tearDown(AuthSession.clear);

  TimelineEvent event({
    required TimelineEventGroup group,
    TimelineEventType type = TimelineEventType.other,
    String sourceEntityId = 'entity-1',
    String sourceEntityType = 'record',
  }) {
    return TimelineEvent(
      eventId: 'evt-1',
      tenantId: 't-1',
      patientId: 'p-1',
      eventType: type,
      eventGroup: group,
      title: 'Test',
      occurredAt: DateTime.utc(2026, 6, 21),
      sourceEntityType: sourceEntityType,
      sourceEntityId: sourceEntityId,
      visibilityScope: TimelineVisibilityScope.doctorAdmin,
    );
  }

  test('routeFor maps appointment and clinical events', () {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );

    expect(
      TimelineEventNavigation.routeFor(
        event(
          group: TimelineEventGroup.appointment,
          type: TimelineEventType.appointmentCreated,
        ),
      ),
      '/appointments/entity-1',
    );
    expect(
      TimelineEventNavigation.routeFor(
        event(
          group: TimelineEventGroup.clinical,
          type: TimelineEventType.clinicalEncounterCreated,
        ),
      ),
      '/clinical-records/entity-1',
    );
  });

  test('routeFor maps file, pdf, consent and patient events', () {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );

    expect(
      TimelineEventNavigation.routeFor(event(group: TimelineEventGroup.file)),
      '/files/entity-1',
    );
    expect(
      TimelineEventNavigation.routeFor(event(group: TimelineEventGroup.pdf)),
      '/pdf-outputs/entity-1',
    );
    expect(
      TimelineEventNavigation.routeFor(event(group: TimelineEventGroup.consent)),
      '/consents/entity-1',
    );
    expect(
      TimelineEventNavigation.routeFor(event(group: TimelineEventGroup.patient)),
      '/patients/entity-1',
    );
  });

  test('routeFor maps physiotherapy session vs referral', () {
    AuthSession.setUser(
      AppUser(
        id: 'd1',
        username: 'doc',
        displayName: 'Doktor',
        role: AppRoles.doctor,
      ),
    );

    expect(
      TimelineEventNavigation.routeFor(
        event(
          group: TimelineEventGroup.physiotherapy,
          sourceEntityType: 'physiotherapy_session',
        ),
      ),
      '/physiotherapy/sessions/entity-1',
    );
    expect(
      TimelineEventNavigation.routeFor(
        event(
          group: TimelineEventGroup.physiotherapy,
          sourceEntityType: 'physiotherapy_referral',
        ),
      ),
      '/physiotherapy/referrals/entity-1',
    );
  });

  test('canNavigate is false without permission', () {
    AuthSession.setUser(
      AppUser(
        id: 'n1',
        username: 'nurse',
        displayName: 'Hemşire',
        role: AppRoles.nurse,
      ),
    );

    expect(
      TimelineEventNavigation.canNavigate(
        event(group: TimelineEventGroup.pdf),
      ),
      isFalse,
    );
  });
}
