/// The address values currently chosen in a PSGC address form.
class AddressSelection {
  const AddressSelection({
    this.province = '',
    this.city = '',
    this.barangay = '',
    this.street = '',
  });

  final String province;
  final String city;
  final String barangay;
  final String street;

  bool get isComplete =>
      province.isNotEmpty &&
      city.isNotEmpty &&
      barangay.isNotEmpty &&
      street.trim().isNotEmpty;
}
