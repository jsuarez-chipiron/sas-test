public class MarkCasesReadOnlyScheduler implements Schedulable {
  public void execute(SchedulableContext ctx) {
    CaseService.setInactiveCasesReadOnly();
  }
}
