package application.rest.v1;

public class IBMBusinessCard {

  String name;
  String email;
  String phone;

  public void setName(String name) {
    this.name = name;
  }

  public String getName() {
    return this.name;
  }

  public void setEmail(String email) {
    this.email = email;
  }

  public String getEmail() {
    return this.email;
  }

  public void setPhone(String phone) {
    this.phone = phone;
  }

  public String getPhone() {
    return this.phone;
  }
}
