/// Wraps a fetch that can fail, so a screen can tell "the server said there is
/// nothing" apart from "we never reached the server".
///
/// Used by the read-only services that previously returned `null` or an empty
/// list on failure, leaving screens with no way to explain themselves.
class ServiceResult<T> {
  const ServiceResult.success(this.data) : message = '', isSuccess = true;

  const ServiceResult.failure(this.message, {this.data}) : isSuccess = false;

  final T? data;

  /// Ready-to-show reason for the failure. Empty on success.
  final String message;

  final bool isSuccess;

  bool get hasError => !isSuccess;
}
