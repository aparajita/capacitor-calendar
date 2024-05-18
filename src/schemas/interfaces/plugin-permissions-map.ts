import type { PermissionState } from '@capacitor/core';
import { PluginPermission } from '../enums/plugin-permission';

export type PluginPermissionsMap = Partial<Record<PluginPermission, PermissionState>>;
