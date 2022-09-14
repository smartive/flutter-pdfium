.PHONY: default \
	clean_bindings \
	dart_bindings \
	prepare_header_ast \
	macos_bindings \
	ios_bindings \
	cleanup_after_bindings \
	bindings

default:
	@echo "No Default Make defined."
	@exit 1

clean_bindings:
	rm -rf ios/Classes/bindings
	rm -rf macos/Classes/bindings
	mkdir -p ios/Classes/bindings
	mkdir -p macos/Classes/bindings

dart_bindings:
	flutter pub run ffigen --config ffigen.yaml

prepare_header_ast:
	clang -Xclang -ast-dump=json -fsyntax-only src/pdfium/fpdfview.h > src/pdfium/fpdfview.json
	clang -Xclang -ast-dump=json -fsyntax-only src/pdfium/fpdf_doc.h > src/pdfium/fpdf_doc.json
	clang -Xclang -ast-dump=json -fsyntax-only src/pdfium/fpdf_text.h > src/pdfium/fpdf_text.json

macos_bindings:
	dart tools/bindings/create_apple_bindings.dart tools/bindings/fpdfview.json macos/Classes/bindings/fpdfview.cpp MACOS_ FPDF
	dart tools/bindings/create_apple_bindings.dart tools/bindings/fpdf_doc.json macos/Classes/bindings/fpdf_doc.cpp MACOS_ FPDFBookmark.* FPDFDest.*
	dart tools/bindings/create_apple_bindings.dart tools/bindings/fpdf_text.json macos/Classes/bindings/fpdf_text.cpp MACOS_ FPDFText.*

ios_bindings:
	dart tools/bindings/create_apple_bindings.dart tools/bindings/fpdfview.json ios/Classes/bindings/fpdfview.cpp IOS_ FPDF
	dart tools/bindings/create_apple_bindings.dart tools/bindings/fpdf_doc.json ios/Classes/bindings/fpdf_doc.cpp IOS_ FPDFBookmark.* FPDFDest.*
	dart tools/bindings/create_apple_bindings.dart tools/bindings/fpdf_text.json ios/Classes/bindings/fpdf_text.cpp IOS_ FPDFText.*

cleanup_after_bindings:
	rm -rf tools/bindings/*.json

bindings: clean_bindings dart_bindings prepare_header_ast macos_bindings ios_bindings style cleanup_after_bindings