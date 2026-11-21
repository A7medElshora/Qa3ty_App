import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qa3ty_app/core/utils/widgets/chips.dart';
import '../../data/models/booking_model.dart';
import '../../data/repos/bookings_repository.dart';

abstract class BookingDetailsState {
  const BookingDetailsState();
}

class BookingDetailsLoading extends BookingDetailsState {
  const BookingDetailsLoading();
}

class BookingDetailsLoaded extends BookingDetailsState {
  final Booking booking;
  const BookingDetailsLoaded(this.booking);
}

class BookingDetailsError extends BookingDetailsState {
  final String message;
  const BookingDetailsError(this.message);
}

class BookingDetailsCubit extends Cubit<BookingDetailsState> {
  final BookingsRepository _repository;

  BookingDetailsCubit(this._repository) : super(const BookingDetailsLoading());

  Future<void> loadBooking(int id) async {
    emit(const BookingDetailsLoading());
    try {
      final booking = await _repository.getBookingById(id);
      if (booking != null) {
        emit(BookingDetailsLoaded(booking));
      } else {
        emit(const BookingDetailsError('الحجز غير موجود'));
      }
    } catch (e) {
      emit(BookingDetailsError(e.toString()));
    }
  }

  Future<void> addPayment({
    required int amount,
    required String paymentMethod,
    required String receiverName,
    String? note,
  }) async {
    if (state is BookingDetailsLoaded) {
      final current = (state as BookingDetailsLoaded).booking;
      await _repository.addPayment(
        bookingId: current.id,
        amount: amount,
        paymentMethod: paymentMethod,
        receiverName: receiverName,
        note: note,
      );
      await loadBooking(current.id);
    }
  }

  Future<void> toggleServiceStatus(String serviceId, BookingServiceStatus newStatus) async {
    if (state is BookingDetailsLoaded) {
      final current = (state as BookingDetailsLoaded).booking;
      await _repository.toggleServiceStatus(current.id, serviceId, newStatus);
      await loadBooking(current.id);
    }
  }

  Future<void> addCustomService(ServiceItem service) async {
    if (state is BookingDetailsLoaded) {
      final current = (state as BookingDetailsLoaded).booking;
      await _repository.addCustomService(current.id, service);
      await loadBooking(current.id);
    }
  }

  Future<void> cancelBooking(String reason, String refundDecision) async {
    if (state is BookingDetailsLoaded) {
      final current = (state as BookingDetailsLoaded).booking;
      await _repository.cancelBooking(current.id, reason, refundDecision);
      await loadBooking(current.id);
    }
  }
}
