cd .\tests\
for %%x in (*.tsc) do del "%%x" 
for %%x in (*.bin) do ..\tools\Shrinkler.exe -d -p -9 -b "%%x" "%%~nx.bin.shr"

cd ..
cmd /c "BeebAsm.exe -v -i shrinkler_test.s.asm -do shrinkler_test.ssd -opt 3"