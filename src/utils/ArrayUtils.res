/**
 * Special function for concatenating paginated responses, it unions the array
 * according to the given comparator and if there are duplicates, it prefers
 * items from the second array - newer response contains latest data.
 * It does not check the passed arrays for duplicates, it is assumed that the
 * server returned non-duplicates so there is only a risk that there are
 * duplicates between the two arrays and only on the edges. For performance
 * reasons this function checks only a few items at the edge, this is controlled
 * by the `overlap` parameter.
 * @param {(a, a) => boolean} comparator
 * @param {number} [overlap=3] setting to 0 forces checking entire array
 * @param {a[]} arr1
 * @param {a[]} arr2
 * @returns {a[]}
 */
let unionByPreferringLast = (~comparator, ~overlap=3, arr1, arr2) => {
  let result = arr2->Array.copy
  let arr1LastIdx = arr1->Array.length - 1
  let stopCheck = overlap === 0 ? 0 : arr1LastIdx - overlap
  for i in arr1LastIdx downto 0 {
    let a1 = arr1->Array.get(i)->Option.getExn
    let duplicate = i > stopCheck && arr2->Array.some(i => comparator(a1, i))
    if !duplicate {
      result->Array.unshift(a1)
    }
  }
  result
}
