// RUN: mlir-opt %s -convert-arm-sme-to-scf -cse -split-input-file | FileCheck %s

//===----------------------------------------------------------------------===//
// arm_sme.tile_load
//===----------------------------------------------------------------------===//

// CHECK-LABEL: func.func @arm_sme_tile_load_hor(
// CHECK-SAME:                                   %[[SRC:.*]]: memref<?x?xi32>) {
// CHECK-DAG:     %[[TILE_ID:.*]] = arm_sme.get_tile_id : i32
// CHECK-DAG:     %[[CAST_TILE_TO_VECTOR:.*]] = arm_sme.cast_tile_to_vector %[[TILE_ID]] : i32 to vector<[4]x[4]xi32>
// CHECK-DAG:     %[[C0:.*]] = arith.constant 0 : index
// CHECK-DAG:     %[[C1:.*]] = arith.constant 1 : index
// CHECK-DAG:     %[[C4:.*]] = arith.constant 4 : index
// CHECK-DAG:     %[[VSCALE:.*]] = vector.vscale
// CHECK-NEXT:    %[[NUM_TILE_SLICES:.*]] = arith.muli %[[C4]], %[[VSCALE]] : index
// CHECK-NEXT:    scf.for %[[TILE_SLICE_INDEX:.*]] = %[[C0]] to %[[NUM_TILE_SLICES]] step %[[C1]] {
// CHECK-NEXT:      %[[PTRUE_S:.*]] = arith.constant dense<true> : vector<[4]xi1>
// CHECK-NEXT:      %[[OFFSET:.*]] = arith.addi %[[C0]], %[[TILE_SLICE_INDEX]] : index
// CHECK-NEXT:      arm_sme.load_tile_slice %[[SRC]]{{\[}}%[[OFFSET]], %[[C0]]], %[[PTRUE_S]], %[[CAST_TILE_TO_VECTOR]], %[[TILE_SLICE_INDEX]] : memref<?x?xi32>, vector<[4]xi1>, vector<[4]x[4]xi32>
func.func @arm_sme_tile_load_hor(%src : memref<?x?xi32>) {
  %c0 = arith.constant 0 : index
  %tile = arm_sme.tile_load %src[%c0, %c0] : memref<?x?xi32>, vector<[4]x[4]xi32>
  return
}

// -----

// CHECK-LABEL: @arm_sme_tile_load_ver
// CHECK: arm_sme.load_tile_slice {{.*}} layout<vertical>
func.func @arm_sme_tile_load_ver(%src : memref<?x?xi32>) {
  %c0 = arith.constant 0 : index
  %tile = arm_sme.tile_load %src[%c0, %c0] layout<vertical> : memref<?x?xi32>, vector<[4]x[4]xi32>
  return
}

//===----------------------------------------------------------------------===//
// arm_sme.tile_store
//===----------------------------------------------------------------------===//

// -----

// CHECK-LABEL: func.func @arm_sme_tile_store_hor(
// CHECK-SAME:                                    %[[TILE:.*]]: vector<[4]x[4]xi32>,
// CHECK-SAME:                                    %[[DEST:.*]]: memref<?x?xi32>) {
// CHECK-DAG:     %[[C0:.*]] = arith.constant 0 : index
// CHECK-DAG:     %[[C1:.*]] = arith.constant 1 : index
// CHECK-DAG:     %[[C4:.*]] = arith.constant 4 : index
// CHECK-DAG:     %[[VSCALE:.*]] = vector.vscale
// CHECK-DAG:     %[[PTRUE_S:.*]] = arith.constant dense<true> : vector<[4]xi1>
// CHECK-DAG:     %[[NUM_TILE_SLICES:.*]] = arith.muli %[[C4]], %[[VSCALE]] : index
// CHECK:         scf.for %[[TILE_SLICE_INDEX:.*]] = %[[C0]] to %[[NUM_TILE_SLICES]] step %[[C1]] {
// CHECK:           %[[OFFSET:.*]] = arith.addi %[[C0]], %[[TILE_SLICE_INDEX]] : index
// CHECK:           arm_sme.store_tile_slice %[[TILE]], %[[TILE_SLICE_INDEX]], %[[PTRUE_S]], %[[DEST]]{{\[}}%[[OFFSET]], %[[C0]]] : memref<?x?xi32>, vector<[4]xi1>, vector<[4]x[4]xi32>
func.func @arm_sme_tile_store_hor(%tile : vector<[4]x[4]xi32>, %dest : memref<?x?xi32>) {
  %c0 = arith.constant 0 : index
  arm_sme.tile_store %tile, %dest[%c0, %c0] : memref<?x?xi32>, vector<[4]x[4]xi32>
  return
}

// -----

// CHECK-LABEL: @arm_sme_tile_store_ver
// CHECK: arm_sme.store_tile_slice {{.*}} layout<vertical>
func.func @arm_sme_tile_store_ver(%tile : vector<[4]x[4]xi32>, %dest : memref<?x?xi32>) {
  %c0 = arith.constant 0 : index
  arm_sme.tile_store %tile, %dest[%c0, %c0] layout<vertical> : memref<?x?xi32>, vector<[4]x[4]xi32>
  return
}

// -----

// CHECK-LABEL: func.func @arm_sme_tile_store_hor_with_mask(
// CHECK-SAME:                                             %[[TILE:.*]]: vector<[4]x[4]xi32>,
// CHECK-SAME:                                             %[[DEST:.*]]: memref<?x?xi32>) {
// CHECK-DAG:     %[[C0:.*]] = arith.constant 0 : index
// CHECK-DAG:     %[[C1:.*]] = arith.constant 1 : index
// CHECK-DAG:     %[[NUM_ROWS:.*]] = arith.constant 3 : index
// CHECK-DAG:     %[[NUM_COLS:.*]] = vector.create_mask %c2 : vector<[4]xi1>
// CHECK-NEXT:    scf.for %[[TILE_SLICE_INDEX:.*]] = %[[C0]] to %[[NUM_ROWS]] step %[[C1]] {
// CHECK-NEXT:      %[[OFFSET:.*]] = arith.addi %[[C0]], %[[TILE_SLICE_INDEX]] : index
// CHECK-NEXT:      arm_sme.store_tile_slice %[[TILE]], %[[TILE_SLICE_INDEX]], %[[NUM_COLS]], %[[DEST]]{{\[}}%[[OFFSET]], %[[C0]]] : memref<?x?xi32>, vector<[4]xi1>, vector<[4]x[4]xi32>
func.func @arm_sme_tile_store_hor_with_mask(%tile : vector<[4]x[4]xi32>, %dest : memref<?x?xi32>) {
  %c0 = arith.constant 0 : index
  %c2 = arith.constant 2 : index
  %c3 = arith.constant 3 : index
  %mask = vector.create_mask %c3, %c2 : vector<[4]x[4]xi1>
  arm_sme.tile_store %tile, %dest[%c0, %c0], %mask : memref<?x?xi32>, vector<[4]x[4]xi32>
  return
}

//===----------------------------------------------------------------------===//
// vector.print
//===----------------------------------------------------------------------===//

// -----

func.func @arm_sme_tile_print(%tile: vector<[4]x[4]xf32>)
{
  vector.print %tile : vector<[4]x[4]xf32>
  return
}
// CHECK-LABEL:   func.func @arm_sme_tile_print(
// CHECK-SAME:                                  %[[TILE:.*]]: vector<[4]x[4]xf32>) {
// CHECK-DAG:     %[[C0:.*]] = arith.constant 0 : index
// CHECK-DAG:     %[[C1:.*]] = arith.constant 1 : index
// CHECK-DAG:     %[[C4:.*]] = arith.constant 4 : index
// CHECK-DAG:     %[[VSCALE:.*]] = vector.vscale
// CHECK-DAG:     %[[NUM_TILE_SLICES:.*]] = arith.muli %[[C4]], %[[VSCALE]] : index
// CHECK-NEXT:      scf.for %[[TILE_SLICE_INDEX:.*]] = %[[C0]] to %[[NUM_TILE_SLICES]] step %[[C1]] {
// CHECK-NEXT:        %[[TILE_SLICE:.*]] = arm_sme.move_tile_slice_to_vector %[[TILE]][%[[TILE_SLICE_INDEX]]] : vector<[4]xf32> from vector<[4]x[4]xf32>
// CHECK-NEXT:        vector.print %[[TILE_SLICE]] : vector<[4]xf32>
