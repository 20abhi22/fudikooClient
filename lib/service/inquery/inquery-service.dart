import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:fudikoclient/api/dio_client.dart';
import 'package:fudikoclient/model/inquery/create-catering-inquery-model.dart';
import 'package:fudikoclient/model/inquery/create-inquery-model.dart';
import 'package:fudikoclient/model/inquery/delete-inquery-model.dart';
import 'package:fudikoclient/model/inquery/list-catering-inquery-model.dart';
import 'package:fudikoclient/model/inquery/list-party-inquery-modal.dart';
import 'package:fudikoclient/model/inquery/response_model.dart';
import 'package:fudikoclient/model/inquery/update-catering-inquery-model.dart';
import 'package:fudikoclient/model/inquery/update-inquery-model.dart';
import 'package:fudikoclient/model/reservation/new-reservation-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant-model.dart';
import 'package:fudikoclient/model/restaurant/restaurant_liked.dart';
import 'package:fudikoclient/utils/tokens.dart';

class InqueryService {
  Future<CreateInqueryModelResponse> createInquery(
    CreateInqueryModel inquerydata,
  ) async {
    final token = await getToken();
    final data = inquerydata.toFormData();
    try {
      final response = await DioClient.dio.post(
        '/customer/enquiry/create',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print(response.data);
        return CreateInqueryModelResponse.fromJson(response.data);
      } else {
        print(response.data);
        return CreateInqueryModelResponse(
          status: false,
          message: 'Reservation failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(e);
      return CreateInqueryModelResponse(
        status: false,
        message: 'Something went wrong: $e',
      );
    }
  }

  //for party

  Future<InqueryListModel> fetchInquerys() async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.get(
        '/customer/enquiry/all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print(response.data);
        return InqueryListModel.fromJson(response.data);
      } else {
        print(response.data);
        return InqueryListModel(status: false, enquiries: []);
      }
    } catch (e) {
      print(e);
      return InqueryListModel(status: false, enquiries: []);
    }
  }

  Future<DeleteInqueryModelResponse> deleteInquery(
    DeleteInqueryModel inquerydata,
  ) async {
    final token = await getToken();
    final data = inquerydata.toFormData();
    try {
      final response = await DioClient.dio.post(
        '/customer/enquiry/delete',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print(response.data);
        return DeleteInqueryModelResponse.fromJson(response.data);
      } else {
        print(response.data);
        return DeleteInqueryModelResponse(
          status: false,
          message: 'Deleting inquery failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(e);
      return DeleteInqueryModelResponse(
        status: false,
        message: 'Something went wrong: $e',
      );
    }
  }

  Future<UpdateInqueryModelResponse> updateInquery(
    UpdateInqueryModel inquerydata,
  ) async {
    final token = await getToken();
    final data = inquerydata.toFormData();
    try {
      final response = await DioClient.dio.post(
        '/customer/enquiry/update',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print(response.data);
        return UpdateInqueryModelResponse.fromJson(response.data);
      } else {
        print(response.data);
        return UpdateInqueryModelResponse(
          status: false,
          message: 'Updating inquery failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(e);
      return UpdateInqueryModelResponse(
        status: false,
        message: 'Something went wrong: $e',
      );
    }
  }

  Future<CreateCateringInqueryModelResponse> createCateringInquery(
    CreateCateringInqueryModel inquerydata,
  ) async {
    final token = await getToken();
    final data = inquerydata.toFormData();
    try {
      final response = await DioClient.dio.post(
        '/customer/catering-enquiry/create',
        data: data,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print(response.data);
        return CreateCateringInqueryModelResponse.fromJson(response.data);
      } else {
        return CreateCateringInqueryModelResponse(
          status: false,
          message: 'Catering enquiry failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      print(e);
      return CreateCateringInqueryModelResponse(
        status: false,
        message: 'Something went wrong: $e',
      );
    }
  }

  Future<CateringInqueryListModel> fetchCateringInquerys() async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.get(
        '/customer/catering-enquiry/all',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        print(response.data);
        return CateringInqueryListModel.fromJson(response.data);
      } else {
        return CateringInqueryListModel(status: false, enquiries: []);
      }
    } catch (e) {
      print(e);
      return CateringInqueryListModel(status: false, enquiries: []);
    }
  }

  Future<DeleteInqueryModelResponse> deleteCateringInquery(
    DeleteInqueryModel data,
  ) async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.post(
        '/customer/catering-enquiry/delete',
        data: data.toFormData(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return DeleteInqueryModelResponse.fromJson(response.data);
      } else {
        return DeleteInqueryModelResponse(status: false, message: 'Failed');
      }
    } catch (e) {
      return DeleteInqueryModelResponse(status: false, message: e.toString());
    }
  }

  Future<UpdateInqueryModelResponse> updateCateringInquery(
    UpdateCateringInqueryModel data,
  ) async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.post(
        '/customer/catering-enquiry/update',
        data: data.toFormData(),
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      if (response.statusCode == 200) {
        return UpdateInqueryModelResponse.fromJson(response.data);
      } else {
        return UpdateInqueryModelResponse(
          status: false,
          message: 'Update failed: ${response.statusCode}',
        );
      }
    } catch (e) {
      return UpdateInqueryModelResponse(
        status: false,
        message: 'Something went wrong: $e',
      );
    }
  }

  Future<EnquiryResponsesListModel> fetchEnquiryResponses() async {
    final token = await getToken();
    try {
      final response = await DioClient.dio.get(
        '/customer/enquiry/responses',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      if (response.statusCode == 200) {
        return EnquiryResponsesListModel.fromJson(response.data);
      }

      return EnquiryResponsesListModel(
        status: false,
        message: 'Failed to fetch responses: ${response.statusCode}',
        responses: [],
      );
    } catch (e) {
      return EnquiryResponsesListModel(
        status: false,
        message: 'Something went wrong: $e',
        responses: [],
      );
    }
  }
}
