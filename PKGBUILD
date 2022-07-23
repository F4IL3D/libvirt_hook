_binname=qemu
_pwd=`pwd`
pkgname=lua-libvirt-helper
pkgver=0.0.1
pkgrel=1
pkgdesc='Lua libvirt hook helper binary'
arch=('x86_64')
url='https://github.com/F4IL3D/lua-libvirt-helper.git'
license=('custom')
# source=('qemu' 'config.json' 'example.json')
# sha256sums=('SKIP')
depends=('git')

prepare() {
  cd "${_pwd}"
  git submodule update --init
}
build() {
  cd "${_pwd}"
  make
}
package() {
  cd "${_pwd}"
  install -Dm755 "${_binname}" "${pkgdir}/etc/libvirt/hooks/${_binname}"
  install -Dm755 "${srcdir}/config.json" "${pkgdir}/etc/libvirt/hooks/config.json"
  install -Dm755 "${srcdir}/example.json" "${pkgdir}/etc/libvirt/hooks/example.json"
}
