# Rebuild some generated files when the tblgen specification changes
ROOT=../../
TARGET=${ROOT}/llvm/lib/Target/RISCV
IntrinsicsRISCVET.td BuiltinsRISCVET.def: intrinsics.py tblgen.py \
	${TARGET}/RISCVInstrFormatsEsperanto.td \
	${TARGET}/RISCVInstrInfoEsperanto.td
	./intrinsics.py

RISCVSystemOperandsEsperanto.td: csrs.py
	cp  ${TARGET}/RISCVSystemOperandsEsperanto.td old
	cat /dev/null > ${TARGET}/RISCVSystemOperandsEsperanto.td
	python3 csrs.py > temp
	mv temp $@
	mv old ${TARGET}/RISCVSystemOperandsEsperanto.td

update: IntrinsicsRISCVET.td BuiltinsRISCVET.def \
	RISCVInstrInfoEsperantoPatterns.td \
	RISCVSystemOperandsEsperanto.td 
	rsync --checksum -i IntrinsicsRISCVET.td ${ROOT}/llvm/include/llvm/IR/IntrinsicsRISCVET.td
	rsync --checksum -i BuiltinsRISCVET.def ${ROOT}/clang/include/clang/Basic/BuiltinsRISCVET.def
	rsync --checksum -i RISCVInstrInfoEsperantoPatterns.td ${TARGET}/RISCVInstrInfoEsperantoPatterns.td
	rsync --checksum -i RISCVSystemOperandsEsperanto.td ${TARGET}/RISCVSystemOperandsEsperanto.td
