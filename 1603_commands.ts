/**
 * 1603_SM vs 1603_SMX Command Definitions
 * 
 * This file contains command definitions for two network device systems:
 * - 1603_SM: Base system with 564 commands
 * - 1603_SMX: Extended system with 609 commands
 * 
 * Key Differences:
 * - 1603_SMX adds support for STS12C (26 commands), POSPORT (14 commands), and BLSR (6 commands)
 * - 1603_SM has unique IPAREA support (4 commands) and more VPL operations
 * - 540 commands are common between both systems
 */

// System type enum
export enum SystemType {
  SM_1603 = '1603_SM',
  SMX_1603 = '1603_SMX',
}

// Device types that differ between systems
export enum DeviceType {
  AAL5 = 'AAL5',
  ATMPORT = 'ATMPORT',
  ATMPROC = 'ATMPROC',
  BLSR = 'BLSR',              // Only in 1603_SMX
  EC1 = 'EC1',
  EQPT = 'EQPT',
  IP = 'IP',
  IPAREA = 'IPAREA',          // Only in 1603_SM
  IPT = 'IPT',
  OC12 = 'OC12',
  OC3 = 'OC3',
  OC48 = 'OC48',
  POSPORT = 'POSPORT',        // Only in 1603_SMX
  RINGMAP = 'RINGMAP',        // Only in 1603_SMX
  SQLMAP = 'SQLMAP',          // Only in 1603_SMX
  STS1 = 'STS1',
  STS12C = 'STS12C',          // Only in 1603_SMX
  STS3C = 'STS3C',
  SYNCN = 'SYNCN',
  T1 = 'T1',
  T3 = 'T3',
  USRLAN = 'USRLAN',
  VCL = 'VCL',
  VPL = 'VPL',
  VT1 = 'VT1',
}

// Commands unique to 1603_SM (not available in 1603_SMX)
export const COMMANDS_ONLY_IN_1603_SM = [
  'DLT-CRS-VPL',
  'DLT-IP',
  'DLT-IPAREA',
  'DLT-VPL',
  'ED-CRS-VPL',
  'ED-FFP-VPL',
  'ED-IP',
  'ED-IPAREA',
  'ENT-CRS-VPL',
  'ENT-IP',
  'ENT-IPAREA',
  'ENT-VPL',
  'INH-PMREPT-VPL',
  'INIT-LOLOG-ATMPORT',
  'OPR-PROTNSW-VPL',
  'RLS-PROTNSW-VPL',
  'RTRV-CRS-VPL',
  'RTRV-FFP-VPL',
  'RTRV-IPAREA',
  'RTRV-LOLOG-ATMPORT',
  'SET-PMMODE-SYNCN',
] as const;

// Commands unique to 1603_SMX (not available in 1603_SM)
export const COMMANDS_ONLY_IN_1603_SMX = [
  'ALW-EX-OC48',
  'ALW-PMREPT-POSPORT',
  'ALW-PMREPT-STS12C',
  'DGN-STS12C',
  'DLT-CRS-STS12C',
  'DLT-RINGMAP',
  'DLT-SQLMAP',
  'DLT-STS12C',
  'ED-CRS-STS12C',
  'ED-FFP-OC48',
  'ED-FFP-STS12C',
  'ED-POSPORT',
  'ED-STS12C',
  'ENT-CRS-STS12C',
  'ENT-RINGMAP',
  'ENT-SQLMAP',
  'ENT-STS12C',
  'EX-SW-OC48',
  'IINH-PMREPT-VPL',
  'INH-EX-OC48',
  'INH-PMREPT-POSPORT',
  'INH-PMREPT-STS12C',
  'INIT-REG-POSPORT',
  'INIT-REG-STS12C',
  'OPR-PROTNSW-OC48',
  'OPR-PROTNSW-STS12C',
  'RLS-PROTNSW-OC48',
  'RLS-PROTNSW-STS12C',
  'RTRV-ALM-BLSR',
  'RTRV-ALM-IPT',
  'RTRV-ALM-POSPORT',
  'RTRV-ALM-STS12C',
  'RTRV-ATTR-BLSR',
  'RTRV-ATTR-IPT',
  'RTRV-ATTR-POSPORT',
  'RTRV-ATTR-STS12C',
  'RTRV-COND-BLSR',
  'RTRV-COND-IPT',
  'RTRV-COND-POSPORT',
  'RTRV-COND-STS12C',
  'RTRV-CRS-STS12C',
  'RTRV-FFP-OC48',
  'RTRV-FFP-STS12C',
  'RTRV-NE-BLSR',
  'RTRV-PM-POSPORT',
  'RTRV-PM-STS12C',
  'RTRV-PMMODE-POSPORT',
  'RTRV-PMMODE-STS12C',
  'RTRV-POSPORT',
  'RTRV-PTHTRC-STS12C',
  'RTRV-RINGMAP',
  'RTRV-SQLMAP',
  'RTRV-STS12C',
  'RTRV-TH-POSPORT',
  'RTRV-TH-STS12C',
  'SET-ATTR-BLSR',
  'SET-ATTR-IPT',
  'SET-ATTR-POSPORT',
  'SET-ATTR-STS12C',
  'SET-IP',
  'SET-NE-BLSR',
  'SET-PMMMODE-SYNCN',
  'SET-PMMODE-POSPORT',
  'SET-PMMODE-STS12C',
  'SET-TH-AAL5',
  'SET-TH-ATMPORT',
  'SET-TH-ATMPROC',
  'SET-TH-POSPORT',
  'SET-TH-STS12C',
] as const;

// Device support matrix
export const DEVICE_SUPPORT = {
  // Devices only in 1603_SMX
  BLSR: { '1603_SM': false, '1603_SMX': true },
  POSPORT: { '1603_SM': false, '1603_SMX': true },
  RINGMAP: { '1603_SM': false, '1603_SMX': true },
  SQLMAP: { '1603_SM': false, '1603_SMX': true },
  STS12C: { '1603_SM': false, '1603_SMX': true },
  
  // Devices only in 1603_SM
  IPAREA: { '1603_SM': true, '1603_SMX': false },
  
  // Devices in both (with different command counts)
  AAL5: { '1603_SM': true, '1603_SMX': true },
  ATMPORT: { '1603_SM': true, '1603_SMX': true },
  ATMPROC: { '1603_SM': true, '1603_SMX': true },
  EC1: { '1603_SM': true, '1603_SMX': true },
  EQPT: { '1603_SM': true, '1603_SMX': true },
  IP: { '1603_SM': true, '1603_SMX': true },
  IPT: { '1603_SM': true, '1603_SMX': true },
  OC12: { '1603_SM': true, '1603_SMX': true },
  OC3: { '1603_SM': true, '1603_SMX': true },
  OC48: { '1603_SM': true, '1603_SMX': true },
  STS1: { '1603_SM': true, '1603_SMX': true },
  STS3C: { '1603_SM': true, '1603_SMX': true },
  SYNCN: { '1603_SM': true, '1603_SMX': true },
  T1: { '1603_SM': true, '1603_SMX': true },
  T3: { '1603_SM': true, '1603_SMX': true },
  USRLAN: { '1603_SM': true, '1603_SMX': true },
  VCL: { '1603_SM': true, '1603_SMX': true },
  VPL: { '1603_SM': true, '1603_SMX': true },
  VT1: { '1603_SM': true, '1603_SMX': true },
} as const;

/**
 * Check if a command is supported in a specific system
 */
export function isCommandSupported(command: string, system: SystemType): boolean {
  if (system === SystemType.SM_1603) {
    return !COMMANDS_ONLY_IN_1603_SMX.includes(command as any);
  } else {
    return !COMMANDS_ONLY_IN_1603_SM.includes(command as any);
  }
}

/**
 * Check if a device type is supported in a specific system
 */
export function isDeviceSupported(device: string, system: SystemType): boolean {
  const support = DEVICE_SUPPORT[device as keyof typeof DEVICE_SUPPORT];
  if (!support) return false;
  return system === SystemType.SM_1603 ? support['1603_SM'] : support['1603_SMX'];
}

/**
 * Get device type from command name
 */
export function getDeviceFromCommand(command: string): string {
  const parts = command.split('-');
  return parts[parts.length - 1];
}

// Type definitions for command validation
export type Command1603SM = typeof COMMANDS_ONLY_IN_1603_SM[number] | string;
export type Command1603SMX = typeof COMMANDS_ONLY_IN_1603_SMX[number] | string;

/**
 * Key feature differences between systems:
 * 
 * 1603_SMX Exclusive Features:
 * - STS12C: High-speed concatenated transport (26 commands)
 * - POSPORT: Packet over SONET/SDH (14 commands)
 * - BLSR: Bidirectional Line Switched Ring topology (6 commands)
 * - RINGMAP/SQLMAP: Enhanced mapping capabilities (6 commands)
 * - Enhanced OC48 operations (7 additional commands)
 * - Enhanced threshold setting (SET-TH-*) for AAL5, ATMPORT, ATMPROC
 * 
 * 1603_SM Exclusive Features:
 * - IPAREA: IP area management (4 commands)
 * - Extended VPL operations: Cross-connect and FFP for VPL (11 commands)
 * - LOLOG for ATMPORT (2 commands)
 */
