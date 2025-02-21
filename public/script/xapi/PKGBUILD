# Maintainer: DarkXero <info@techxero.com>
pkgname=xlapit-cli
_destname1="/"
pkgver=1.0
pkgrel=1
pkgdesc="XeroLinux Arch Post Install Toolkit"
arch=('any')
url="https://github.com/XeroLinux"
license=('GPL3')
makedepends=('git')
makedepends=('git' 'wget')
provides=("${pkgname}")
options=(!strip !emptydirs)
source=(${pkgname}::"git+${url}/${pkgname}")
sha256sums=('SKIP')
package() {
	install -dm755 ${pkgdir}${_destname1}
	cp -r ${srcdir}/${pkgname}${_destname1}/* ${pkgdir}${_destname1}
	rm ${srcdir}/${pkgname}/push.sh
	rm ${srcdir}/${pkgname}/README.md
	rm ${srcdir}/${pkgname}/PKGBUILD
	rm ${srcdir}/${pkgname}/LICENSE
}
