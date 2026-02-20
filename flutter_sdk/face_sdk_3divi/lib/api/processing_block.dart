part of face_sdk_3divi;

///Interface object used to work with estimators from Processing Block API.
class ProcessingBlock extends _ComplexObject {
  ProcessingBlock(super.dll_handle, super.impl);

  @override
  void dispose() {
    final exception = _getException();
    final destructor = _dll_handle.lookupFunction<
            _ProcessingBlock_destroyProcessingBlock_c,
            _ProcessingBlock_destroyProcessingBlock_dart>(
        'TDVProcessingBlock_destroyBlock');

    destructor(_impl, exception);

    tdvCheckException(exception, _dll_handle);
  }

  void process(Context ctx) {
    _call_context(ctx);
  }

  Context _call_context(Context ctx) {
    final exception = _getException();
    final constructor = _dll_handle.lookupFunction<
            _ProcessingBlock_processContext_c,
            _ProcessingBlock_processContext_dart>(
        'TDVProcessingBlock_processContext');
    constructor(_impl, ctx._impl, exception);

    tdvCheckException(exception, _dll_handle);

    return ctx;
  }
}
