namespace Trintech.PowerShell.Utilities
{
    using System;
    using System.Collections.Generic;

    public class CombinationTree<T> : Dictionary<T, CombinationTree<T>?>
    {
        private Func<T,T,T> Combine;

        public CombinationTree(Func<T,T,T> combiner) : base()
        {
            this.Combine = combiner;
        }

        public CombinationTree(Func<T,T,T> combiner, IDictionary<T, U?> rawTrsee) where U : IDictionary<T, U?> : base(rawTree)
        {
            this.Combine = combiner;
        }

        public IEnumerator<T> Combinations
        {
            get
            {
                foreach (KeyValuePair<T, CombinationTree<T>?> entry in this) {
                    T value = entry.Key;
                    CombinationTree? subTree = entry.Value;
                    if (null != subTree) {
                        foreach (T subCombination in subTree.Combinations) {
                            T combination = Combine(value, subCombination);
                            yield return combination;
                        }
                    } else {
                        yield return value;
                    }
                }
            }
        }
    }

    public class ListCombinationTree<E> : CombinationTree<IList<E>>
    {
        public static const Func<IList<E>, IList<E>, IList<E>> LIST_COMBINER = (parent, child) => {
            var combined = new List<E>(parent);
            foreach (E element in child) {
                combined.Add(element);
            }
            return combined;
        }

        public ListCombinationTree() : base(LIST_COMBINER) { }

        public ListCombinationTree(IDictionary<IList<E>, U?> rawTree) where U : IDictionary<IList<E>, U?> : base(rawTree) { }
    }

    public class SortedListCombinationTree<E> : CombinationTree<SortedList<E>>
    {
        public static const Func<SortedList<E>, SortedList<E>, SortedList<E>> SORTED_LIST_COMBINER = (parent, child) => {
            var combined = new SortedList<E>(parent);
            foreach (E element in child) {
                combined.Add(element);
            }
            return combined;
        }

        public SortedListCombinationTree() : base(SORTED_LIST_COMBINER) { }

        public SortedListCombinationTree(IDictionary<SortedList<E>, U?> rawTree) where U : IDictionary<SortedList<E>, U?> : base(rawTree) { }
    }

    public class SetCombinationTree<E> : CombinationTree<ISet<E>>
    {
        public static const Func<ISet<E>, ISet<E>, ISet<E>> SET_COMBINER = (parent, child) => {
            var combined = new HashSet<E>(parent);
            foreach (E element in child) {
                combined.Add(element);
            }
            return combined;
        }

        public SetCombinationTree() : base(SET_COMBINER) { }

        public SetCombinationTree(IDictionary<ISet<E>, U?> rawTree) where U : IDictionary<ISet<E>, U?> : base(SET_COMBINER, rawTree) { }
    }

    public class SortedSetCombinationTree<E> : CombinationTree<SortedSet<E>>
    {
        public static const Func<SortedSet<E>, SortedSet<E>, SortedSet<E>> SORTED_SET_COMBINER = (parent, child) => {
            var combined = new SortedSet<E>(parent);
            foreach (E element in child) {
                combined.Add(element);
            }
            return combined;
        }

        public SortedSetCombinationTree() : base(SORTED_SET_COMBINER) { }

        public SortedSetCombinationTree(IDictionary<SortedSet<E>, U?> rawTree) where U : IDictionary<SortedSet<E>, U?> : base(SORTED_SET_COMBINER, rawTree) { }
    }

    public class DictionaryCombinationTree<K,V> : CombinationTree<IDictionary<K,V>>
    {
        public static const Func<IDictionary<K,V>, IDictionary<K,V>, IDictionary<K,V>> DICTIONARY_COMBINER = (parent, child) => {
            var combined = new Dictionary<K,V>(parent);
            foreach (KeyValuePair<K,V> entry in child) {
                combined[entry.Key] = entry.Value;
            }
            return combined;
        }

        public DictionaryCombinationTree() : base(DICTIONARY_COMBINER) { }

        public DictionaryCombinationTree(IDictionary<IDictionary<K,V>, U?> rawTree) where U : IDictionary<IDictionary<K,V>, U?> : base(DICTIONARY_COMBINER, rawTree) { }
    }

    public class SortedDictionaryCombinationTree<K,V> : CombinationTree<IDictionary<K,V>>
    {
        public static const Func<SortedDictionary<K,V>, SortedDictionary<K,V>, SortedDictionary<K,V>> SORTED_DICTIONARY_COMBINER = (parent, child) => {
            var combined = new SortedDictionary<K,V>(parent);
            foreach (KeyValuePair<K,V> entry in child) {
                combined[entry.Key] = entry.Value;
            }
        }

        public SortedDictionaryCombinationTree() : base(SORTED_DICTIONARY_COMBINER) { }

        public SortedDictionaryCombinationTree(IDictionary<SortedDictionary<K,V>, U?> rawTree) where U : IDictionary<SortedDictionary<K,V>, U?> : base(DICTIONARY_COMBINER, rawTree) { }
    }
}