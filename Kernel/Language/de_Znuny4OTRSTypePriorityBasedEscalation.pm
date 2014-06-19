# --
# Kernel/Language/de_Znuny4OTRSTypePriorityBasedEscalation.pm - the German translation of the texts of Znuny4OTRSTypePriorityBasedEscalation
# Copyright (C) 2013 Znuny GmbH, http://znuny.com/
# --

package Kernel::Language::de_Znuny4OTRSTypePriorityBasedEscalation;

use strict;
use warnings;

sub Data {
    my $Self = shift;

    # SysConfigs
    $Self->{Translation}->{"This configuration defines if the first response time should be calculated based on the first owner change or the first agent response."} = "Diese Konfiguration definiert ob die Reaktionszeit beim ersten Besitzerwechsel oder der ersten Kundenantwort gelöscht werden soll.";
    $Self->{Translation}->{"This configuration defines a list of ticket types to which the priority based escalation should be restricted. Only tickets with a ticket type of this list will get checked for priority based escalation. All tickets will escalate priority based if this configuration is deactivated or has no types configured."} = 'Diese Konfiguration definiert eine Liste von Ticket-Typen, für die eine prioritätsbasierte Eskalation möglich ist. Nur Tickets mit einem Typen aus dieser Liste werden auf eine prioritätsbasierte Eskalation geprüft. Es werden alle Tickets auf eine prioritätsbasierte Eskalation geprüft, wenn diese Konfiguration deaktiviert ist oder keine Ticket-Typen konfiguriert sind.';
    $Self->{Translation}->{"First owner change"} = 'Erster Besitzerwechsel';
    $Self->{Translation}->{"First agent response"} = 'Erste Kundenantwort';

    return 1;
}

1;
