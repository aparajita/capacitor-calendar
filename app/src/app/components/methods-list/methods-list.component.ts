import { Component, NgZone } from '@angular/core';
import {
  IonButton,
  IonButtons,
  IonIcon,
  IonItem,
  IonLabel,
  IonList,
  IonListHeader,
  IonModal,
  IonPicker,
  IonPickerColumn,
  IonPickerColumnOption,
  IonPickerLegacy,
  IonToolbar,
} from '@ionic/angular/standalone';
import {
  CalendarChooserDisplayStyle,
  CalendarChooserSelectionStyle,
  CapacitorCalendar,
  PluginPermission,
  PluginPermissionsMap,
  ReminderRecurrenceFrequency,
} from '@ebarooni/capacitor-calendar';
import { StoreService } from '../../store/store.service';
import { EventsListViewModalComponent } from '../events-list-view-modal/events-list-view-modal.component';
import { Capacitor, CapacitorException, PermissionState } from '@capacitor/core';
import { Device } from '@capacitor/device';
import { IonModalCustomEvent, OverlayEventDetail, PickerColumnChangeEventDetail } from '@ionic/core';

@Component({
  selector: 'app-methods-list',
  templateUrl: './methods-list.component.html',
  styleUrl: './methods-list.component.css',
  imports: [
    EventsListViewModalComponent,
    IonIcon,
    IonItem,
    IonLabel,
    IonList,
    IonListHeader,
    IonModal,
    IonPickerLegacy,
    IonToolbar,
    IonButtons,
    IonButton,
    IonPicker,
    IonPickerColumn,
    IonPickerColumnOption,
  ],
  standalone: true,
})
export class MethodsListComponent {
  public calendarChooserIsOpen = false;
  public displayStyle: CalendarChooserDisplayStyle = CalendarChooserDisplayStyle.ALL_CALENDARS;
  public selectionStyle: CalendarChooserSelectionStyle = CalendarChooserSelectionStyle.SINGLE;
  public permissionChooserIsOpen = false;
  public permissionToCheck: PluginPermission = PluginPermission.READ_CALENDAR;

  constructor(
    private readonly storeService: StoreService,
    private readonly zone: NgZone
  ) {}

  private async tryCall<T>(call: () => Promise<T>, logResponse = true): Promise<Awaited<T> | undefined> {
    try {
      const response = await call();

      if (logResponse) {
        if (response !== undefined) {
          this.storeService.dispatchLog(JSON.stringify(response, null, 2));
        } else {
          this.storeService.dispatchLog('[success]');
        }
      }

      return response;
    } catch (error) {
      if (error instanceof CapacitorException) {
        this.storeService.dispatchLog(`${error.message} (${error.data?.['type']})`, true);
      } else {
        this.storeService.dispatchLog(JSON.stringify(error, null, 2), true);
      }

      return undefined;
    }
  }

  // Permissions

  public onPermissionDidChange(value: PickerColumnChangeEventDetail['value']): void {
    if (typeof value === 'string') {
      this.permissionToCheck = value as unknown as PluginPermission;
    }
  }

  public async onDidDismissPermissionChooser(event: IonModalCustomEvent<OverlayEventDetail>): Promise<void> {
    this.permissionChooserIsOpen = false;

    if (event.detail.role === 'confirm') {
      await this.checkPermission(this.permissionToCheck);
    }
  }

  public async checkPermission(alias: PluginPermission): Promise<void> {
    const response = await this.tryCall<{ result: PermissionState }>(() =>
      CapacitorCalendar.checkPermission({ alias: alias })
    );

    if (response) {
      const permissionState: Partial<PluginPermissionsMap> = {};
      permissionState[alias] = response.result;
      this.storeService.updateState({ permissions: permissionState });
    }
  }

  public async checkAllPermissions(): Promise<void> {
    const response = await this.tryCall(async () => CapacitorCalendar.checkAllPermissions());

    if (response) {
      this.storeService.updateState({ permissions: response });
    }
  }

  public async requestReadOnlyCalendarAccess(): Promise<void> {
    const response = await this.tryCall(async () => CapacitorCalendar.requestReadOnlyCalendarAccess());

    if (response) {
      this.storeService.updateState({ permissions: { readCalendar: response.result } });
    }
  }

  // iOS only
  public async requestWriteOnlyCalendarAccess(): Promise<void> {
    const response = await this.tryCall(async () => CapacitorCalendar.requestWriteOnlyCalendarAccess());

    if (response) {
      // On iOS < 17, requesting write-only access is the same as read/write.
      const permissions: Partial<PluginPermissionsMap> = { writeCalendar: response.result };
      const info = await Device.getInfo();

      if (info.platform === 'ios' && info.osVersion < '17.0.0') {
        permissions['readCalendar'] = response.result;
      }

      this.storeService.updateState({ permissions });
    }
  }

  public async requestFullCalendarAccess(): Promise<void> {
    const response = await this.tryCall(async () => CapacitorCalendar.requestFullCalendarAccess());

    if (response) {
      this.storeService.updateState({
        permissions: {
          readCalendar: response.result,
          writeCalendar: response.result,
        },
      });
    }
  }

  public async requestFullRemindersAccess(): Promise<void> {
    const response = await this.tryCall(async () => CapacitorCalendar.requestFullRemindersAccess());

    if (response) {
      this.storeService.updateState({
        permissions: {
          readReminders: response.result,
          writeReminders: response.result,
        },
      });
    }
  }

  public async requestAllPermissions(): Promise<void> {
    const response = await this.tryCall(async () => CapacitorCalendar.requestAllPermissions());

    if (response) {
      this.storeService.updateState({ permissions: response });
    }
  }

  // Calendars

  public onSelectionStyleDidChange(value: PickerColumnChangeEventDetail['value']): void {
    if (typeof value === 'number') {
      this.selectionStyle = value as unknown as CalendarChooserSelectionStyle;
    }
  }

  public onDisplayStyleDidChange(value: PickerColumnChangeEventDetail['value']): void {
    if (typeof value === 'number') {
      this.displayStyle = value as unknown as CalendarChooserDisplayStyle;
    }
  }

  public async onDidDismissCalendarChooser(event: IonModalCustomEvent<OverlayEventDetail>): Promise<void> {
    this.calendarChooserIsOpen = false;

    if (event.detail.role === 'confirm') {
      await this.selectCalendarsWithPrompt(this.selectionStyle, this.displayStyle);
    }
  }

  public async selectCalendarsWithPrompt(
    selectionStyle: CalendarChooserSelectionStyle,
    displayStyle: CalendarChooserDisplayStyle
  ): Promise<void> {
    await this.tryCall(async () => CapacitorCalendar.selectCalendarsWithPrompt({ selectionStyle, displayStyle }));
  }

  public async listCalendars(options?: { access: CalendarChooserDisplayStyle }): Promise<void> {
    await this.tryCall(async () => CapacitorCalendar.listCalendars(options));
  }

  public async getDefaultCalendar(): Promise<void> {
    await this.tryCall(async () => CapacitorCalendar.getDefaultCalendar());
  }

  public async createCalendar(): Promise<void> {
    await this.tryCall(async () =>
      CapacitorCalendar.createCalendar({
        title: 'Capacitor Calendar',
        color: '#fe48b3',
      })
    );
  }

  public async deleteCalendar(): Promise<void> {
    const result = await this.tryCall(async () =>
      CapacitorCalendar.selectCalendarsWithPrompt({
        selectionStyle: CalendarChooserSelectionStyle.SINGLE,
        displayStyle: CalendarChooserDisplayStyle.ALL_CALENDARS,
      })
    );

    if (result && result.result.length > 0) {
      await this.tryCall(async () => CapacitorCalendar.deleteCalendar({ id: result.result[0].id }));
    }
  }

  public async openCalendar(): Promise<void> {
    await this.tryCall(
      async () =>
        CapacitorCalendar.openCalendar({
          date: Date.now() + 24 * 60 * 60 * 1000, // tomorrow
        }),
      false
    );
  }

  // Events

  public async createEvent(): Promise<void> {
    const now = Date.now();
    await this.tryCall(async () =>
      CapacitorCalendar.createEvent({
        title: 'Capacitor Calendar',
        startDate: now,
        endDate: now + 2 * 60 * 60 * 1000,
        location: 'Capacitor Calendar Land',
        isAllDay: false,
        alertOffsetInMinutes: 15,
      })
    );
  }

  public async createEventWithPrompt(): Promise<void> {
    const now = Date.now();
    await this.tryCall(async () =>
      CapacitorCalendar.createEventWithPrompt({
        title: 'Capacitor Calendar',
        startDate: now,
        endDate: now + 2 * 60 * 60 * 1000,
        location: 'Capacitor Calendar Land',
        isAllDay: false,
        alertOffsetInMinutes: 15,
      })
    );
  }

  public async listEventsInRange(): Promise<void> {
    await this.tryCall(async () =>
      CapacitorCalendar.listEventsInRange({
        startDate: Date.now(),
        endDate: Date.now() + 6 * 7 * 24 * 60 * 60 * 1000, // 6 weeks from now
      })
    );
  }

  public async deleteEventsById(ids: string[]): Promise<void> {
    await this.tryCall(async () =>
      CapacitorCalendar.deleteEventsById({
        ids: ids,
      })
    );
  }

  // Reminders

  public async getDefaultRemindersList(): Promise<void> {
    await this.tryCall(async () => CapacitorCalendar.getDefaultRemindersList());
  }

  public async getRemindersLists(): Promise<void> {
    await this.tryCall(async () => CapacitorCalendar.getRemindersLists());
  }

  public async createReminder(): Promise<void> {
    await this.tryCall(async () =>
      CapacitorCalendar.createReminder({
        title: 'Capacitor Calendar',
        notes: 'A CapacitorJS Plugin',
        priority: 5,
        dueDate: Date.now(),
        isCompleted: false,
        url: 'https://capacitor-calendar.pages.dev/',
        location: 'Remote',
        recurrence: {
          frequency: ReminderRecurrenceFrequency.WEEKLY,
          interval: 3,
          end: Date.now() + 6 * 7 * 24 * 60 * 60 * 1000, // 6 weeks from now
        },
      })
    );
  }

  public async openReminders(): Promise<void> {
    await this.tryCall(async () => CapacitorCalendar.openReminders(), false);
  }

  protected readonly Capacitor = Capacitor;
  protected readonly CalendarChooserSelectionStyle = CalendarChooserSelectionStyle;
  protected readonly CalendarChooserDisplayStyle = CalendarChooserDisplayStyle;
  protected readonly PluginPermission = PluginPermission;
}
