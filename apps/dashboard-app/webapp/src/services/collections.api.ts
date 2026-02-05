import { createApi } from "@reduxjs/toolkit/query/react";

import { AppConfig } from "@config/config";
import { SnackMessage } from "@config/constant";
import { enqueueSnackbarMessage } from "@slices/commonSlice/common";

import { baseQueryWithReauth } from "./BaseQuery";

interface Collections {
  count: number;
  collections: Collection[];
}

export interface Collection {
  id: number;
  name: string;
  createdOn: string;
  createdBy: string;
  updatedOn: string;
  updatedBy: string;
}

export interface AddCollectionPayload {
  name: string;
}

export const collectionApi = createApi({
  reducerPath: "collectionApi",
  baseQuery: baseQueryWithReauth,
  tagTypes: ["Collections"],
  endpoints: (builder) => ({
    getCollections: builder.query<Collections, void>({
      query: () => AppConfig.serviceUrls.collections,
      providesTags: ["Collections"],
    }),
    addCollection: builder.mutation<Collection, AddCollectionPayload>({
      query: (payload) => ({
        url: AppConfig.serviceUrls.collections,
        method: "POST",
        body: payload,
      }),
      invalidatesTags: ["Collections"],
      async onQueryStarted(_payload, { dispatch, queryFulfilled }) {
        try {
          await queryFulfilled;
          dispatch(
            enqueueSnackbarMessage({
              message: SnackMessage.success.addCollections || "Collection added successfully",
              type: "success",
            }),
          );
        } catch (error: any) {
          dispatch(
            enqueueSnackbarMessage({
              message:
                error.error?.data?.message ||
                SnackMessage.error.addCollections ||
                "Failed to add collection",
              type: "error",
            }),
          );
        }
      },
    }),
  }),
});

export const { useGetCollectionsQuery, useAddCollectionMutation } = collectionApi;
