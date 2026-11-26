# Third-party notices

mdbdart is licensed under the GNU Affero General Public License v3.0 only (see
`LICENSE`), with the additional permission in `LICENSE-EXCEPTION.md`. It
includes code and data from the projects below, which are used
under their own licences.

## mdb-reader

- Upstream: https://github.com/andipaetzold/mdb-reader
- Ported from commit `4e08263a03b61af71c8d4f1736423baeb5c55500`
- Licence: MIT

The Dart sources under `lib/src/` and the tests under `test/` that start with
"Ported from mdb-reader" are translations of mdb-reader's TypeScript sources
and tests. Each such file names the upstream file it was ported from.

The test databases under `test/data/` were copied unchanged from mdb-reader at
the same commit; `test/data/README.md` lists the upstream path of each.
mdb-reader's README says its test databases were copied from the Jackcess
repository (https://github.com/jahlborn/jackcess, Apache License 2.0), and
`test/data/real/SOURCE.md` names the source of `ASampleDatabase.accdb`.

```
MIT License

Copyright (c) 2020 Andi Pätzold

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

## iconv-lite

mdb-reader's Windows-1252 decoder (`src/dependencies/iconv-lite/index.ts`),
ported to `lib/src/dependencies/windows1252.dart`, uses a character table from
iconv-lite.

- Upstream: https://github.com/ashtuchkin/iconv-lite
- Licence: MIT

```
Copyright (c) 2011 Alexander Shtuchkin

Permission is hereby granted, free of charge, to any person obtaining
a copy of this software and associated documentation files (the
"Software"), to deal in the Software without restriction, including
without limitation the rights to use, copy, modify, merge, publish,
distribute, sublicense, and/or sell copies of the Software, and to
permit persons to whom the Software is furnished to do so, subject to
the following conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

```
