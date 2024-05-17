import { Component, EventEmitter, Inject, Output, ViewChild } from '@angular/core';
import {
  IonButton,
  IonButtons,
  IonCheckbox,
  IonCol,
  IonContent,
  IonGrid,
  IonHeader,
  IonItem,
  IonLabel,
  IonList,
  IonListHeader,
  IonModal,
  IonProgressBar,
  IonRow,
  IonToolbar,
} from '@ionic/angular/standalone';
import { CalendarEvent, CapacitorCalendar } from '@ebarooni/capacitor-calendar';
import { BehaviorSubject } from 'rxjs';
import { LetDirective } from '@ngrx/component';
import { DatePipe, DOCUMENT } from '@angular/common';

@Component({
  selector: 'app-events-list-view-modal',
  templateUrl: './events-list-view-modal.component.html',
  imports: [
    IonModal,
    IonHeader,
    IonToolbar,
    IonCheckbox,
    IonContent,
    IonList,
    LetDirective,
    IonItem,
    IonLabel,
    IonCheckbox,
    IonProgressBar,
    IonButton,
    IonGrid,
    IonRow,
    IonCol,
    IonButtons,
    IonListHeader,
    DatePipe,
  ],
  standalone: true,
})
export class EventsListViewModalComponent {
  @Output() deleteEvents = new EventEmitter<string[]>();
  @ViewChild('modal') modal?: IonModal;
  public loading = false;
  public checkboxStates: { [key: string]: boolean } = {};
  public startDate?: Date;
  public endDate?: Date;
  readonly events$ = new BehaviorSubject<CalendarEvent[]>([]);

  constructor(@Inject(DOCUMENT) private readonly document: Document) {}

  async present(): Promise<void> {
    if (this.modal) {
      this.loading = true;
      await this.fetchEvents();
      this.loading = false;
      this.modal.presentingElement = this.document.querySelector('app-api.ion-page') ?? undefined;
      await this.modal.present();
    } else {
      throw new Error('Modal not present');
    }
  }

  dispatchEvents(): void {
    const idsToDelete = Object.entries(this.checkboxStates)
      .map(([key, value]) => {
        return { id: key, checked: value };
      })
      .filter((event) => event.checked)
      .map((event) => event.id);
    this.deleteEvents.emit(idsToDelete);
    void this.modal?.dismiss();
  }

  dispose(): void {
    this.checkboxStates = {};
    this.startDate = undefined;
    this.endDate = undefined;
  }

  private async fetchEvents(): Promise<void> {
    const now = Date.now();
    const inTwoWeeks = now + 2 * 7 * 24 * 60 * 60 * 1000;
    this.startDate = new Date(now);
    this.endDate = new Date(inTwoWeeks);

    try {
      const { result } = await CapacitorCalendar.listEventsInRange({
        startDate: now,
        endDate: now + 2 * 7 * 24 * 60 * 60 * 1000,
      });
      this.events$.next(result);
    } catch (error) {
      console.warn(error);
    }
  }
}
