import { Component } from '@angular/core';
import { IonContent, IonRefresher, IonRefresherContent } from '@ionic/angular/standalone';
import { HeaderComponent } from '../../components/header/header.component';
import { PermissionsStatusComponent } from '../../components/permissions-status/permissions-status.component';
import { MethodsListComponent } from '../../components/methods-list/methods-list.component';
import { StoreService } from '../../store/store.service';
import { CapacitorCalendar } from '@ebarooni/capacitor-calendar';
import type { RefresherEventDetail } from '@ionic/core/components';

@Component({
  selector: 'app-api',
  templateUrl: './api.component.html',
  imports: [
    IonContent,
    HeaderComponent,
    PermissionsStatusComponent,
    MethodsListComponent,
    IonRefresher,
    IonRefresherContent,
  ],
  standalone: true,
})
export class ApiComponent {
  constructor(readonly storeService: StoreService) {}

  public async handlePageRefresh(event: CustomEvent<RefresherEventDetail>): Promise<void> {
    try {
      const result = await CapacitorCalendar.checkAllPermissions();
      this.storeService.updateState({ permissions: result });
      this.storeService.dispatchLog(JSON.stringify(result, null, 2));
    } catch (error) {
      this.storeService.dispatchLog(JSON.stringify(error, null, 2), true);
    } finally {
      event.detail.complete();
    }
  }
}
