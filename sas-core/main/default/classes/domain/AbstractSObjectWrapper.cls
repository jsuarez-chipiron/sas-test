/**
 * Represents an individual sObject with one-to-one mapping to the underlying
 * sObject.
 *
 * Concrete implementations of this object represent specific sObject types.
 */

public without sharing abstract class AbstractSObjectWrapper {
  public String name;
  public Id id;
  public Datetime createdDate { get; private set; } // cannot be modified manually
  public Datetime lastModifiedDate { get; private set; } // cannot be modified manually

  public SObject underlyingSObject { get; private set; }

  public abstract void updateSObjectFields();

  @SuppressWarnings('PMD.EmptyStatementBlock')
  public AbstractSObjectWrapper() {
  }

  public AbstractSObjectWrapper(SObject obj) {
    this.underlyingSObject = obj;
    this.id = obj.Id;
    this.name = (String) obj.get('Name');
    this.createdDate = (Datetime) obj.get('CreatedDate');
    this.lastModifiedDate = (Datetime) obj.get('LastModifiedDate');
  }
}