# --
# Copyright (C) 2001-2018 OTRS AG, https://otrs.com/
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - 33b1ad6acf39acae4eb40e88f0256fa2e8b50fc4 - Kernel/System/Priority.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::System::Priority;

use strict;
use warnings;

use Kernel::System::CacheInternal;
use Kernel::System::SysConfig;
use Kernel::System::Time;
use Kernel::System::Valid;

use vars qw(@ISA $VERSION);

=head1 NAME

Kernel::System::Priority - priority lib

=head1 SYNOPSIS

All ticket priority functions.

=head1 PUBLIC INTERFACE

=over 4

=cut

=item new()

create an object

    use Kernel::Config;
    use Kernel::System::Encode;
    use Kernel::System::Log;
    use Kernel::System::Main;
    use Kernel::System::DB;
    use Kernel::System::Priority;

    my $ConfigObject = Kernel::Config->new();
    my $EncodeObject = Kernel::System::Encode->new(
        ConfigObject => $ConfigObject,
    );
    my $LogObject = Kernel::System::Log->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
    );
    my $MainObject = Kernel::System::Main->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
    );
    my $DBObject = Kernel::System::DB->new(
        ConfigObject => $ConfigObject,
        EncodeObject => $EncodeObject,
        LogObject    => $LogObject,
        MainObject   => $MainObject,
    );
    my $PriorityObject = Kernel::System::Priority->new(
        ConfigObject => $ConfigObject,
        LogObject    => $LogObject,
        DBObject     => $DBObject,
        MainObject   => $MainObject,
        EncodeObject => $EncodeObject,
    );

=cut

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {};
    bless( $Self, $Type );

    # check needed objects
    for (qw(DBObject ConfigObject LogObject MainObject EncodeObject)) {
        $Self->{$_} = $Param{$_} || die "Got no $_!";
    }
    $Self->{ValidObject}         = Kernel::System::Valid->new(%Param);
    $Self->{CacheInternalObject} = Kernel::System::CacheInternal->new(
        %Param,
        Type => 'Priority',
        TTL  => 60 * 60 * 24 * 20,
    );

    return $Self;
}

=item PriorityList()

return a priority list as hash

    my %List = $PriorityObject->PriorityList(
        Valid => 0,
    );

=cut

sub PriorityList {
    my ( $Self, %Param ) = @_;

    # check valid param
    if ( !defined $Param{Valid} ) {
        $Param{Valid} = 1;
    }

    # create cachekey
    my $CacheKey;
    if ( $Param{Valid} ) {
        $CacheKey = 'PriorityList::Valid';
    }
    else {
        $CacheKey = 'PriorityList::All';
    }

    # check cache
    my $Cache = $Self->{CacheInternalObject}->Get(
        Key => $CacheKey,
    );
    return %{$Cache} if $Cache;

    # create sql
    my $SQL = 'SELECT id, name FROM ticket_priority ';
    if ( $Param{Valid} ) {
        $SQL .= "WHERE valid_id IN ( ${\(join ', ', $Self->{ValidObject}->ValidIDsGet())} )";
    }

    return if !$Self->{DBObject}->Prepare( SQL => $SQL );

    # fetch the result
    my %Data;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $Data{ $Row[0] } = $Row[1];
    }

    # set cache
    $Self->{CacheInternalObject}->Set(
        Key   => $CacheKey,
        Value => \%Data,
    );

    return %Data;
}

=item PriorityGet()

get a priority

    my %List = $PriorityObject->PriorityGet(
        PriorityID => 123,
        UserID     => 1,
    );

=cut

sub PriorityGet {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(PriorityID UserID)) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    # check cache
    my $Cache = $Self->{CacheInternalObject}->Get(
        Key => 'PriorityGet' . $Param{PriorityID},
    );
    return %{$Cache} if $Cache;

    # ask database
# ---
    # Znuny4OTRS-TypePriorityBasedEscalation
# ---
    #     return if !$Self->{DBObject}->Prepare(
    #         SQL => 'SELECT id, name, valid_id, create_time, create_by, change_time, change_by '
    #             . 'FROM ticket_priority WHERE id = ?',
    #         Bind  => [ \$Param{PriorityID} ],
    #         Limit => 1,
    #     );
    return if !$Self->{DBObject}->Prepare(
        SQL =>
            'SELECT id, name, valid_id, create_time, create_by, change_time, change_by, calendar_name, first_response_time, first_response_notify, update_time, update_notify, solution_time, solution_notify '
            . 'FROM ticket_priority WHERE id = ?',
        Bind  => [ \$Param{PriorityID} ],
        Limit => 1,
    );

# ---

    # fetch the result
    my %Data;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $Data{ID}         = $Row[0];
        $Data{Name}       = $Row[1];
        $Data{ValidID}    = $Row[2];
        $Data{CreateTime} = $Row[3];
        $Data{CreateBy}   = $Row[4];
        $Data{ChangeTime} = $Row[5];
        $Data{ChangeBy}   = $Row[6];

# ---
        # Znuny4OTRS-TypePriorityBasedEscalation
# ---
        $Data{Calendar}            = $Row[7];
        $Data{FirstResponseTime}   = $Row[8];
        $Data{FirstResponseNotify} = $Row[9];
        $Data{UpdateTime}          = $Row[10];
        $Data{UpdateNotify}        = $Row[11];
        $Data{SolutionTime}        = $Row[12];
        $Data{SolutionNotify}      = $Row[13];

# ---
    }

    # set cache
    $Self->{CacheInternalObject}->Set(
        Key   => 'PriorityGet' . $Param{PriorityID},
        Value => \%Data,
    );

    return %Data;
}

=item PriorityAdd()

add a ticket priority

    my $True = $PriorityObject->PriorityAdd(
        Name    => 'Prio',
        ValidID => 1,
        UserID  => 1,
    );

=cut

sub PriorityAdd {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(Name ValidID UserID)) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

# ---
    # Znuny4OTRS-TypePriorityBasedEscalation
# ---
    #     return if !$Self->{DBObject}->Do(
    #         SQL => 'INSERT INTO ticket_priority (name, valid_id, create_time, create_by, '
    #             . 'change_time, change_by) VALUES '
    #             . '(?, ?, current_timestamp, ?, current_timestamp, ?)',
    #         Bind => [
    #             \$Param{Name}, \$Param{ValidID}, \$Param{UserID}, \$Param{UserID},
    #         ],
    #     );
    for my $DefaultNullAttr (
        qw(FirstResponseTime FirstResponseNotify UpdateTime UpdateNotify SolutionTime SolutionNotify))
    {
        $Param{$DefaultNullAttr} ||= 0;
    }
    return if !$Self->{DBObject}->Do(
        SQL =>
            'INSERT INTO ticket_priority (name, valid_id, create_time, create_by, calendar_name, first_response_time, first_response_notify, update_time, update_notify, solution_time, solution_notify, '
            . 'change_time, change_by) VALUES '
            . '(?, ?, current_timestamp, ?, ?, ?, ?, ?, ?, ?, ?, current_timestamp, ?)',
        Bind => [
            \$Param{Name}, \$Param{ValidID}, \$Param{UserID}, \$Param{Calendar}, \$Param{FirstResponseTime},
            \$Param{FirstResponseNotify}, \$Param{UpdateTime}, \$Param{UpdateNotify}, \$Param{SolutionTime},
            \$Param{SolutionNotify}, \$Param{UserID},
        ],
    );

# ---

    # get new state id
    return if !$Self->{DBObject}->Prepare(
        SQL   => 'SELECT id FROM ticket_priority WHERE name = ?',
        Bind  => [ \$Param{Name} ],
        Limit => 1,
    );

    # fetch the result
    my $ID;
    while ( my @Row = $Self->{DBObject}->FetchrowArray() ) {
        $ID = $Row[0];
    }

    return if !$ID;

    # delete cache
    $Self->{CacheInternalObject}->CleanUp();

    return $ID;
}

=item PriorityUpdate()

update a existing ticket priority

    my $True = $PriorityObject->PriorityUpdate(
        PriorityID     => 123,
        Name           => 'New Prio',
        ValidID        => 1,
        CheckSysConfig => 0,   # (optional) default 1
        UserID         => 1,
    );

=cut

sub PriorityUpdate {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    for (qw(PriorityID Name ValidID UserID)) {
        if ( !$Param{$_} ) {
            $Self->{LogObject}->Log(
                Priority => 'error',
                Message  => "Need $_!"
            );
            return;
        }
    }

    # check CheckSysConfig param
    if ( !defined $Param{CheckSysConfig} ) {
        $Param{CheckSysConfig} = 1;
    }

# ---
    # Znuny4OTRS-TypePriorityBasedEscalation
# ---
    #     return if !$Self->{DBObject}->Do(
    #         SQL => 'UPDATE ticket_priority SET name = ?, valid_id = ?, '
    #             . 'change_time = current_timestamp, change_by = ? WHERE id = ?',
    #         Bind => [
    #             \$Param{Name}, \$Param{ValidID}, \$Param{UserID}, \$Param{PriorityID},
    #         ],
    #     );
    for my $DefaultNullAttr (
        qw(FirstResponseTime FirstResponseNotify UpdateTime UpdateNotify SolutionTime SolutionNotify))
    {
        $Param{$DefaultNullAttr} ||= 0;
    }
    $Param{Calendar} ||= '';

    return if !$Self->{DBObject}->Do(
        SQL => 'UPDATE ticket_priority SET name = ?, valid_id = ?, '
            . 'change_time = current_timestamp, change_by = ?, calendar_name = ?, first_response_time = ?, first_response_notify = ?, update_time = ?, update_notify = ?, solution_time = ?, solution_notify = ? WHERE id = ?',
        Bind => [
            \$Param{Name}, \$Param{ValidID}, \$Param{UserID}, \$Param{Calendar}, \$Param{FirstResponseTime},
            \$Param{FirstResponseNotify}, \$Param{UpdateTime}, \$Param{UpdateNotify}, \$Param{SolutionTime},
            \$Param{SolutionNotify}, \$Param{PriorityID},
        ],
    );

# ---

    # delete cache
    $Self->{CacheInternalObject}->CleanUp();

    # check all sysconfig options
    return 1 if !$Param{CheckSysConfig};

    # create a time object locally, needed for the local SysConfigObject
    my $TimeObject = Kernel::System::Time->new( %{$Self} );

    # create a sysconfig object locally for performance reasons
    my $SysConfigObject = Kernel::System::SysConfig->new(
        %{$Self},
        TimeObject => $TimeObject,
    );

    # check all sysconfig options and correct them automatically if neccessary
    $SysConfigObject->ConfigItemCheckAll();
}

=item PriorityLookup()

returns the id or the name of a priority

    my $PriorityID = $PriorityObject->PriorityLookup(
        Priority => '3 normal',
    );

    my $Priority = $PriorityObject->PriorityLookup(
        PriorityID => 1,
    );

=cut

sub PriorityLookup {
    my ( $Self, %Param ) = @_;

    # check needed stuff
    if ( !$Param{Priority} && !$Param{PriorityID} ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => 'Need Priority or PriorityID!'
        );
        return;
    }

    # get (already cached) priority list
    my %PriorityList = $Self->PriorityList(
        Valid => 0,
    );

    my $Key;
    my $Value;
    my $ReturnData;
    if ( $Param{PriorityID} ) {
        $Key        = 'PriorityID';
        $Value      = $Param{PriorityID};
        $ReturnData = $PriorityList{ $Param{PriorityID} };
    }
    else {
        $Key   = 'Priority';
        $Value = $Param{Priority};
        my %PriorityListReverse = reverse %PriorityList;
        $ReturnData = $PriorityListReverse{ $Param{Priority} };
    }

    # check if data exists
    if ( !defined $ReturnData ) {
        $Self->{LogObject}->Log(
            Priority => 'error',
            Message  => "No $Key for $Value found!",
        );
        return;
    }

    return $ReturnData;
}

1;

=back

=head1 TERMS AND CONDITIONS

This software is part of the OTRS project (L<https://otrs.org/>).

This software comes with ABSOLUTELY NO WARRANTY. For details, see
the enclosed file COPYING for license information (GPL). If you
did not receive this file, see L<https://www.gnu.org/licenses/gpl-3.0.txt>.

=cut

=cut
