# --
# Copyright (C) 2001-2018 OTRS AG, https://otrs.com/
# Copyright (C) 2012-2018 Znuny GmbH, http://znuny.com/
# --
# $origin: otrs - 4acf480a361f3a8cf6d34e5ce204d3b41cceba74 - Kernel/Modules/AdminPriority.pm
# --
# This software comes with ABSOLUTELY NO WARRANTY. For details, see
# the enclosed file COPYING for license information (GPL). If you
# did not receive this file, see https://www.gnu.org/licenses/gpl-3.0.txt.
# --

package Kernel::Modules::AdminPriority;

use strict;
use warnings;

use Kernel::Language qw(Translatable);

our $ObjectManagerDisabled = 1;

sub new {
    my ( $Type, %Param ) = @_;

    # allocate new hash for object
    my $Self = {%Param};
    bless( $Self, $Type );

    return $Self;
}

sub Run {
    my ( $Self, %Param ) = @_;

    my $LayoutObject   = $Kernel::OM->Get('Kernel::Output::HTML::Layout');
    my $ParamObject    = $Kernel::OM->Get('Kernel::System::Web::Request');
    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');

    # ------------------------------------------------------------ #
    # change
    # ------------------------------------------------------------ #
    if ( $Self->{Subaction} eq 'Change' ) {
        my %GetParam = ();
        $GetParam{PriorityID} = $ParamObject->GetParam( Param => 'PriorityID' ) || '';
        my %PriorityData = $PriorityObject->PriorityGet(
            PriorityID => $GetParam{PriorityID},
            UserID     => $Self->{UserID},
        );
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Change',
            %PriorityData,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminPriority',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # change action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'ChangeAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my ( %GetParam, %Errors );

        # get params
# ---
# Znuny4OTRS-TypePriorityBasedEscalation
# ---
#        for my $Parameter (qw(PriorityID Name ValidID)) {
        for my $Parameter (qw(PriorityID Name ValidID Calendar FirstResponseTime FirstResponseNotify UpdateTime UpdateNotify SolutionTime SolutionNotify)) {
# ---
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check needed data
        for my $Needed (qw(Name ValidID)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        # if no errors occurred
        if ( !%Errors ) {

            # update priority
            my $Update = $PriorityObject->PriorityUpdate(
                %GetParam,
                UserID => $Self->{UserID}
            );

            if ($Update) {
                $Self->_Overview();
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify( Info => Translatable('Priority updated!') );
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AdminPriority',
                    Data         => \%Param,
                );
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => Translatable('Error') );
        $Self->_Edit(
            Action => 'Change',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminPriority',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'Add' ) {
        my %GetParam = ();
        $GetParam{PriorityID} = $ParamObject->GetParam( Param => 'PriorityID' ) || '';
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Self->_Edit(
            Action => 'Add',
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminPriority',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------ #
    # add action
    # ------------------------------------------------------------ #
    elsif ( $Self->{Subaction} eq 'AddAction' ) {

        # challenge token check for write action
        $LayoutObject->ChallengeTokenCheck();

        my ( %GetParam, %Errors );

        # get params
# ---
# Znuny4OTRS-TypePriorityBasedEscalation
# ---
#        for my $Parameter (qw(PriorityID Name ValidID)) {
        for my $Parameter (qw(PriorityID Name ValidID Calendar FirstResponseTime FirstResponseNotify UpdateTime UpdateNotify SolutionTime SolutionNotify)) {
# ---
            $GetParam{$Parameter} = $ParamObject->GetParam( Param => $Parameter ) || '';
        }

        # check needed data
        for my $Needed (qw(Name ValidID)) {
            if ( !$GetParam{$Needed} ) {
                $Errors{ $Needed . 'Invalid' } = 'ServerError';
            }
        }

        # if no errors occurred
        if ( !%Errors ) {

            my $NewPriority = $PriorityObject->PriorityAdd(
                %GetParam,
                UserID => $Self->{UserID},
            );

            if ($NewPriority) {
                $Self->_Overview();
                my $Output = $LayoutObject->Header();
                $Output .= $LayoutObject->NavigationBar();
                $Output .= $LayoutObject->Notify( Info => Translatable('Priority added!') );
                $Output .= $LayoutObject->Output(
                    TemplateFile => 'AdminPriority',
                    Data         => \%Param,
                );
                $Output .= $LayoutObject->Footer();
                return $Output;
            }
        }

        # something has gone wrong
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Notify( Priority => Translatable('Error') );
        $Self->_Edit(
            Action => 'Add',
            Errors => \%Errors,
            %GetParam,
        );
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminPriority',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }

    # ------------------------------------------------------------
    # overview
    # ------------------------------------------------------------
    else {
        $Self->_Overview();
        my $Output = $LayoutObject->Header();
        $Output .= $LayoutObject->NavigationBar();
        $Output .= $LayoutObject->Output(
            TemplateFile => 'AdminPriority',
            Data         => \%Param,
        );
        $Output .= $LayoutObject->Footer();
        return $Output;
    }
}

sub _Edit {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionOverview' );

    # get valid list
    my %ValidList        = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();
    my %ValidListReverse = reverse %ValidList;

    $Param{ValidOptionStrg} = $LayoutObject->BuildSelection(
        Data       => \%ValidList,
        Name       => 'ValidID',
        SelectedID => $Param{ValidID} || $ValidListReverse{valid},
        Class      => 'Modernize Validate_Required ' . ( $Param{Errors}->{'ValidIDInvalid'} || '' ),
    );

# ---
# Znuny4OTRS-TypePriorityBasedEscalation
# ---
    # generate CalendarOptionStrg
    my %CalendarList;
    for my $CalendarNumber ( '', 1 .. 50 ) {
        if ( $Kernel::OM->Get('Kernel::Config')->Get("TimeVacationDays::Calendar$CalendarNumber") ) {
            $CalendarList{$CalendarNumber} = "Calendar $CalendarNumber - "
                . $Kernel::OM->Get('Kernel::Config')->Get( "TimeZone::Calendar" . $CalendarNumber . "Name" );
        }
    }
    $Param{CalendarOptionStrg} = $LayoutObject->BuildSelection(
        Data         => \%CalendarList,
        Name         => 'Calendar',
        SelectedID   => $Param{Calendar},
        Translation  => 0,
        PossibleNone => 1,
    );

    my %NotifyLevelList = (
        10 => '10%',
        20 => '20%',
        30 => '30%',
        40 => '40%',
        50 => '50%',
        60 => '60%',
        70 => '70%',
        80 => '80%',
        90 => '90%',
    );
    $Param{FirstResponseNotifyOptionStrg} = $LayoutObject->BuildSelection(
        Data         => \%NotifyLevelList,
        Translation  => 0,
        Name         => 'FirstResponseNotify',
        SelectedID   => $Param{FirstResponseNotify},
        PossibleNone => 1,
    );
    $Param{UpdateNotifyOptionStrg} = $LayoutObject->BuildSelection(
        Data         => \%NotifyLevelList,
        Translation  => 0,
        Name         => 'UpdateNotify',
        SelectedID   => $Param{UpdateNotify},
        PossibleNone => 1,
    );
    $Param{SolutionNotifyOptionStrg} = $LayoutObject->BuildSelection(
        Data         => \%NotifyLevelList,
        Translation  => 0,
        Name         => 'SolutionNotify',
        SelectedID   => $Param{SolutionNotify},
        PossibleNone => 1,
    );
# ---

    $LayoutObject->Block(
        Name => 'OverviewUpdate',
        Data => {
            %Param,
            %{ $Param{Errors} },
        },
    );

    # shows header
    if ( $Param{Action} eq 'Change' ) {
        $LayoutObject->Block( Name => 'HeaderEdit' );
    }
    else {
        $LayoutObject->Block( Name => 'HeaderAdd' );
    }

    return 1;
}

sub _Overview {
    my ( $Self, %Param ) = @_;

    my $LayoutObject = $Kernel::OM->Get('Kernel::Output::HTML::Layout');

    $LayoutObject->Block(
        Name => 'Overview',
        Data => \%Param,
    );

    $LayoutObject->Block( Name => 'ActionList' );
    $LayoutObject->Block( Name => 'ActionAdd' );

    $LayoutObject->Block(
        Name => 'OverviewResult',
        Data => \%Param,
    );

    my $PriorityObject = $Kernel::OM->Get('Kernel::System::Priority');

    # get priority list
    my %PriorityList = $PriorityObject->PriorityList(
        Valid  => 0,
        UserID => $Self->{UserID},
    );

    # if there are any priorities defined, they are shown
    if (%PriorityList) {

        # get valid list
        my %ValidList = $Kernel::OM->Get('Kernel::System::Valid')->ValidList();

        for my $PriorityID ( sort { $a <=> $b } keys %PriorityList ) {

            # get priority data
            my %PriorityData = $PriorityObject->PriorityGet(
                PriorityID => $PriorityID,
                UserID     => $Self->{UserID},
            );

            $LayoutObject->Block(
                Name => 'OverviewResultRow',
                Data => {
                    %PriorityData,
                    PriorityID => $PriorityID,
                    Valid      => $ValidList{ $PriorityData{ValidID} },
                },
            );
        }
    }

    # otherwise a no data found msg is displayed
    else {
        $LayoutObject->Block(
            Name => 'NoDataFoundMsg',
            Data => {},
        );
    }
    return 1;
}

1;
