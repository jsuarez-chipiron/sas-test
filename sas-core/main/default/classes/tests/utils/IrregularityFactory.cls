public with sharing class IrregularityFactory {
  public static FlightIrregularity createCancellation(Flight f) {
    FlightIrregularity fi = new FlightIrregularity(
      new FlightIrregularities__c()
    );

    fi.id = Id.valueOf('001xa000003DIlo'); // TODO: fix;
    fi.cancellationTime = DateTime.newInstance(2020, 1, 1, 1, 1, 1);
    fi.code = 'TECH';
    fi.description = null;
    fi.durationMinutes = 60;
    fi.eligibleForEU261 = FlightIrregularity.EU261Eligibility.Yes;
    fi.flightId = f.id;
    fi.reason = 'Plane damaged';
    fi.type = 'Cancellation (departure)';

    return fi;
  }

  public static FlightIrregularity createDelay(Flight f) {
    FlightIrregularity fi = new FlightIrregularity(
      new FlightIrregularities__c()
    );

    fi.id = Id.valueOf('001xa000003DIlo'); // TODO: fix;
    fi.cancellationTime = DateTime.newInstance(2020, 1, 1, 1, 1, 1);
    fi.code = 'FA';
    fi.description = null;
    fi.durationMinutes = 60;
    fi.eligibleForEU261 = FlightIrregularity.EU261Eligibility.Yes;
    fi.flightId = f.id;
    fi.reason = 'Special request caused issues';
    fi.type = 'Delay (departure)';

    return fi;
  }
}
